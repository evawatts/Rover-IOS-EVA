// Theme toggle functionality
document.addEventListener('DOMContentLoaded', function() {
  const themeToggle = document.querySelector('.theme-toggle')
  
  if (themeToggle) {
    themeToggle.addEventListener('click', function() {
      let currentTheme = document.documentElement.getAttribute('data-theme')
      let newTheme
      
      if (currentTheme === 'dark') {
        newTheme = 'light'
      } else if (currentTheme === 'light') {
        newTheme = 'system'
      } else {
        newTheme = 'dark'
      }
      
      document.documentElement.setAttribute('data-theme', newTheme)
    })
  }
})

// Mobile navigation toggle (if needed in future)
document.addEventListener('DOMContentLoaded', function() {
  const navToggle = document.querySelector('.nav-toggle button')
  const sidebar = document.querySelector('.sidebar')
  
  if (navToggle && sidebar) {
    navToggle.addEventListener('click', function() {
      sidebar.classList.toggle('mobile-open')
    })
  }
})