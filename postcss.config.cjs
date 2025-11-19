const tailwindcss = require('tailwindcss')
const tailwindcssconfig = require('./tailwind.config.cjs')

module.exports = {
  plugins: [tailwindcss(tailwindcssconfig)],
}
