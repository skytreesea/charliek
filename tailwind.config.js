/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js'
  ],
  theme: {
    extend: {
      colors: {
        'theme-bg': '#FAF9F6',
        'theme-card': '#FFFFFF',
        'theme-primary': '#D4A373',
        'theme-text': '#433E3F',
        'theme-border': 'rgba(212, 163, 115, 0.2)',
        'theme-hover': 'rgba(212, 163, 115, 0.15)',
      },
      fontFamily: {
        'theme-heading': ['var(--font-heading)', 'system-ui', 'sans-serif'],
        'theme-body': ['var(--font-body)', 'system-ui', 'sans-serif'],
        'theme-button': ['var(--font-button)', 'system-ui', 'sans-serif'],
        'theme-link': ['var(--font-link)', 'system-ui', 'sans-serif'],
        'theme-nav': ['var(--font-nav)', 'system-ui', 'sans-serif'],
        'theme-code': ['var(--font-code)', 'monospace'],
        'theme-footer': ['var(--font-footer)', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [],
}
