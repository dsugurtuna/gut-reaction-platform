// Runs Tailwind over src/index.css during `vite build`. Without this file the
// @tailwind directives were left unprocessed and the dashboard shipped unstyled.
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};
