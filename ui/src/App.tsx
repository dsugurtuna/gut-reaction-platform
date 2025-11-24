import { Routes, Route } from 'react-router-dom';
import Layout from './components/Layout';
import Dashboard from './pages/Dashboard';
import CohortBuilder from './pages/CohortBuilder';
import AuditLog from './pages/AuditLog';
import NLPAnalysis from './pages/NLPAnalysis';

function App() {
  return (
    <Layout>
      <Routes>
        <Route path="/" element={<Dashboard />} />
        <Route path="/cohort" element={<CohortBuilder />} />
        <Route path="/nlp" element={<NLPAnalysis />} />
        <Route path="/audit" element={<AuditLog />} />
      </Routes>
    </Layout>
  );
}

export default App;
