import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  optimizeDeps: {
    exclude: ['lucide-react'],
  },
  build: {
    rollupOptions: {
      output: {
        manualChunks: (id) => {
          // Vendor chunks
          if (id.includes('node_modules')) {
            if (id.includes('react') || id.includes('react-dom')) {
              return 'react-vendor';
            }
            if (id.includes('leaflet') || id.includes('react-leaflet')) {
              return 'leaflet-vendor';
            }
            if (id.includes('@supabase')) {
              return 'supabase-vendor';
            }
            if (id.includes('lucide-react')) {
              return 'icons-vendor';
            }
            return 'vendor';
          }

          // Component chunks
          if (id.includes('/src/components/')) {
            if (id.includes('Dashboard') || id.includes('Admin') || id.includes('SuperAdmin')) {
              return 'dashboard-components';
            }
            if (id.includes('Tracking') || id.includes('Map') || id.includes('Route')) {
              return 'tracking-components';
            }
            if (id.includes('Vehicle') || id.includes('Driver')) {
              return 'fleet-components';
            }
            return 'components';
          }

          // API chunks
          if (id.includes('/src/api/')) {
            return 'api';
          }
        },
        entryFileNames: 'assets/[name]-[hash].js',
        chunkFileNames: 'assets/[name]-[hash].js',
        assetFileNames: 'assets/[name]-[hash].[ext]'
      }
    },
    sourcemap: true,
    minify: 'esbuild',
    target: 'es2015',
    chunkSizeWarningLimit: 1000,
  },
  define: {
    __APP_VERSION__: JSON.stringify(process.env.npm_package_version),
  },
});
