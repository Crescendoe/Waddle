import { defineConfig } from 'astro/config';

export default defineConfig({
  site: 'https://waddle-app.web.app',
  outDir: './dist',
  build: {
    assets: '_assets'
  }
});
