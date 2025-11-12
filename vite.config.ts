import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';
import { defineConfig } from 'vite';
import Rails from 'vite-plugin-rails';

export default defineConfig({
	plugins: [
		react({
			babel: {
				plugins: ['babel-plugin-react-compiler'],
			},
		}),
		tailwindcss(),
		Rails({
			envVars: { RAILS_ENV: 'development' },
		}),
	],
});
