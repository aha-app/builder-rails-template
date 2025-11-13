import tailwindcss from '@tailwindcss/vite';
import react from '@vitejs/plugin-react';
import { defineConfig } from 'vite';
import ViteRuby from 'vite-plugin-ruby';
import EnvironmentPlugin from 'vite-plugin-environment';

export default defineConfig({
	plugins: [
		react({
			babel: {
				plugins: ['babel-plugin-react-compiler'],
			},
		}),
		tailwindcss(),
		ViteRuby(),
		EnvironmentPlugin({ RAILS_ENV: 'development' }),
	],
});
