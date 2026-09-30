# Why it's built this way

## The problem in two sentences

Clinical research needs hospital records, free-text reports and genomic data joined up, but they
sit in different systems, in different shapes, under different rules. Each preparation step
(cleaning, extracting, linking, checking outputs) is usually done by hand, which is slow, hard to
repeat and hard to audit.

## Design choices

**Why split the work into four services?**
Because each step touches different data and carries a different risk. The text service never
needs genomic paths, and the linkage service never sees free text. Separate services make those
boundaries visible and let each one have its own dependencies and tests. The honest cost: for
this much code a single application would also work, and would be simpler to run.

**Why rules, not a trained model, for VTE?**
Because a term list plus negation cues can be read, checked and explained line by line, and it is
the baseline any model has to beat. Ordinary automation is often enough; a model is worth adding
only once there is evidence the rules fall short.

**Why check for negation in a window of six tokens before the term?**
Because a common way to write a negative finding is to put the cue just before it ("no evidence
of PE"). It is a simplified form of the NegEx idea of looking for cue phrases near a finding. The
cues must match whole words: an earlier version
matched substrings, so "known", "diagnosis" and "normal" counted as "no" and real findings were
hidden. Regression tests now cover that.

**Why does the NLP service fall back from SciSpacy to a blank tokenizer?**
Because matching only uses tokenisation, so the answer does not depend on which model is
installed. The fallback keeps the tests offline and the service running. `/health` reports which
pipeline loaded, so the fallback is visible rather than silent.

**Why is `confidence` a fixed 0.95?**
Because the extractor has not been evaluated, so there is no honest probability to report. The
field is kept for the API's shape and documented as a placeholder. Making uncertainty visible is
better than a number that looks precise.

**Why use a vision-language model to check redacted documents?**
Because the failures that matter are visual: a name in a margin, a redaction box you can see
through, text inside an embedded screenshot. Text rules cannot see those.

**Why ship the auditor mocked, and say so everywhere?**
Because the prompt, the response schema and the parsing can be built and tested before choosing
a model, but a canned answer must never be mistaken for a real check. The class has
`MOCKED = True`, and `/health` and every response report it.

**Why does the auditor fail closed?**
Because a reply it cannot read tells you nothing about the document. Treating it as unsafe means
a broken model or a changed response format blocks release instead of letting files through.

**Why R for harmonisation and linkage?**
Because these steps are data-frame work (rename, map, parse dates, join, filter) that dplyr
expresses compactly, and many health data analysts already work in R.

**Why keep the R rules in separate files from the I/O?**
Because the tests used to re-implement the rules inside the test files, so they kept passing
whatever the service did. Now the service and the tests source the same `*_rules.R` files.

**Why not call the harmonised output OMOP?**
Because it is not: there are no concept IDs, vocabularies or `drug_exposure` table. Using the
name would promise interoperability the code does not give.

**Why does the linkage code expect the ID bridge from elsewhere?**
Because whoever holds the mapping between clinical and genomic IDs should be separate from whoever
runs the analysis. The code joins on a bridge table it is given; it does not create or see
identifiers beyond what it is handed.

**Why pin NumPy and ruff?**
Because unpinned tools changed underneath the code. NumPy 2 broke `import spacy` for spaCy 3.5,
and new ruff releases add default rules. Pinned versions mean a red build points at a code change.

**Why do the integration tests check response bodies?**
Because checking only that a service starts let a broken endpoint through: `/extract/vte`
returned HTTP 500 on every call while CI stayed happy. The job now asserts on what comes back.

**Why is the deploy job manual-only?**
Because there is no cluster behind this repository, and permission to build is not permission to
deploy. Deploying needs its own decision, its own credentials and someone who owns the result.

**Why keep Kubernetes and Terraform that have never been deployed?**
Because they record the intended runtime shape, and CI can at least check that the manifests are
structurally valid. The docs list every gap that would stop them working today.

## Questions worth asking

**1. How accurate is the VTE extractor?**
Unknown, and the documentation says so. The next step is a small annotated set of synthetic or
openly licensed reports, with precision and recall produced by a command in the repository. The
error analysis would look first at known weak spots: cues after the term ("PE unlikely"), hedges
("cannot exclude"), historical or family mentions ("history of DVT", "mother had a PE"), and
windows that cross sentence boundaries. Usage is not quality: a tool that runs on many reports
is not thereby a tool that is right about them.

**2. If a model checks redactions, why trust its "safe"?**
You should not, on its own. A second model is a critic, not a verifier: it can find leaks, but its
silence does not prove there are none, and agreement between two models is not verification
either. The auditor should rank documents for human review, not replace that review. To know how
far to rely on it, seed test documents with known leaks and measure how many it misses. The total
human effort (checking and correcting, not only running the model) is the number that matters.

**3. Does joining clinical and genomic data raise the re-identification risk?**
Yes, which is why the design keeps the bridge table with a separate party, keeps each service to
the data it needs, keeps identifiers out of logs and checks outputs for small counts before
release. The current small-cell check is basic: one column at a time, a fixed threshold, no
cross-tabulations and no protection against differencing between releases. Connecting any real
data would be a separate decision, with its own approvals, from building the code.

## What's next

1. Evaluate the VTE rules on an annotated synthetic set and publish the numbers with the command
   that produces them.
2. Put a real vision-language model behind the auditor, render PDF pages to images, and measure
   its miss rate on seeded leaks.
3. Add authentication before any endpoint could be exposed, and fill the Kubernetes gaps listed
   in [DEPLOYMENT.md](DEPLOYMENT.md).
4. Either map prescriptions to OMOP properly or keep the flat format and say why.
