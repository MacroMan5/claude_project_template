# 🖥️ UI Testing Prompt (Puppeteer MCP)

## Context
You are creating comprehensive UI tests using Puppeteer MCP for browser automation, visual regression testing, and end-to-end user flow validation. These tests ensure the application works correctly from a user's perspective.

## Puppeteer MCP Setup

### Prerequisites
```bash
# Install Puppeteer MCP
claude mcp add puppeteer -s user -- npx -y @modelcontextprotocol/server-puppeteer

# Verify installation
claude mcp list
```

### Configuration
Ensure `.mcp.json` includes:
```json
{
  "puppeteer": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-puppeteer"],
    "type": "stdio"
  }
}
```

## UI Testing Strategy

### Test Categories

#### 1. Visual Regression Tests
Ensure UI components render correctly:
```javascript
describe('Visual Regression Tests', () => {
  it('should match homepage snapshot', async () => {
    await page.goto('http://localhost:3000')
    await page.waitForSelector('.main-content')
    
    const screenshot = await page.screenshot({
      fullPage: true,
      path: 'tests/screenshots/homepage.png'
    })
    
    expect(screenshot).toMatchImageSnapshot({
      customDiffConfig: { threshold: 0.1 },
      failureThreshold: 0.05,
      failureThresholdType: 'percent'
    })
  })
})
```

#### 2. User Flow Tests
Test complete user journeys:
```javascript
describe('User Registration Flow', () => {
  it('should complete registration process', async () => {
    // Navigate to registration
    await page.goto('http://localhost:3000/register')
    
    // Fill form
    await page.type('#email', 'test@example.com')
    await page.type('#password', 'SecurePass123!')
    await page.type('#confirmPassword', 'SecurePass123!')
    
    // Submit
    await page.click('#submit-button')
    
    // Verify success
    await page.waitForNavigation()
    await expect(page.url()).toBe('http://localhost:3000/dashboard')
    await expect(page).toHaveText('Welcome, test@example.com')
  })
})
```

#### 3. Component Interaction Tests
Verify interactive elements:
```javascript
describe('Component Interactions', () => {
  it('should handle dropdown selection', async () => {
    await page.goto('http://localhost:3000/settings')
    
    // Open dropdown
    await page.click('.dropdown-trigger')
    await page.waitForSelector('.dropdown-menu', { visible: true })
    
    // Select option
    await page.click('[data-value="option2"]')
    
    // Verify selection
    const selectedValue = await page.$eval('.dropdown-trigger', 
      el => el.textContent
    )
    expect(selectedValue).toBe('Option 2')
  })
})
```

#### 4. Responsive Design Tests
Test across different viewports:
```javascript
describe('Responsive Design', () => {
  const viewports = [
    { name: 'mobile', width: 375, height: 667 },
    { name: 'tablet', width: 768, height: 1024 },
    { name: 'desktop', width: 1920, height: 1080 }
  ]
  
  viewports.forEach(({ name, width, height }) => {
    it(`should render correctly on ${name}`, async () => {
      await page.setViewport({ width, height })
      await page.goto('http://localhost:3000')
      
      // Test mobile menu
      if (name === 'mobile') {
        await expect(page).toHaveSelector('.mobile-menu-button')
        await page.click('.mobile-menu-button')
        await expect(page).toHaveSelector('.mobile-menu', { visible: true })
      }
      
      // Take screenshot for visual comparison
      await page.screenshot({
        path: `tests/screenshots/${name}-layout.png`
      })
    })
  })
})
```

#### 5. Performance Tests
Monitor page performance:
```javascript
describe('Performance Tests', () => {
  it('should load within performance budget', async () => {
    const metrics = await page.evaluate(() => {
      const navigation = performance.getEntriesByType('navigation')[0]
      const paint = performance.getEntriesByType('paint')
      
      return {
        domContentLoaded: navigation.domContentLoadedEventEnd - navigation.domContentLoadedEventStart,
        loadComplete: navigation.loadEventEnd - navigation.loadEventStart,
        firstPaint: paint.find(p => p.name === 'first-paint')?.startTime,
        firstContentfulPaint: paint.find(p => p.name === 'first-contentful-paint')?.startTime
      }
    })
    
    expect(metrics.firstContentfulPaint).toBeLessThan(1500) // 1.5s
    expect(metrics.domContentLoaded).toBeLessThan(3000) // 3s
  })
})
```

## Page Object Model (POM)

### Structure
```javascript
// pages/LoginPage.js
class LoginPage {
  constructor(page) {
    this.page = page
    this.emailInput = '#email'
    this.passwordInput = '#password'
    this.submitButton = '#login-submit'
    this.errorMessage = '.error-message'
  }
  
  async navigate() {
    await this.page.goto('http://localhost:3000/login')
  }
  
  async login(email, password) {
    await this.page.type(this.emailInput, email)
    await this.page.type(this.passwordInput, password)
    await this.page.click(this.submitButton)
  }
  
  async getErrorMessage() {
    await this.page.waitForSelector(this.errorMessage)
    return this.page.$eval(this.errorMessage, el => el.textContent)
  }
}
```

### Usage
```javascript
describe('Login Tests with POM', () => {
  let loginPage
  
  beforeEach(async () => {
    loginPage = new LoginPage(page)
    await loginPage.navigate()
  })
  
  it('should show error on invalid credentials', async () => {
    await loginPage.login('invalid@email.com', 'wrong')
    const error = await loginPage.getErrorMessage()
    expect(error).toBe('Invalid email or password')
  })
})
```

## Accessibility Testing

### WCAG Compliance
```javascript
describe('Accessibility Tests', () => {
  it('should meet WCAG 2.1 AA standards', async () => {
    await page.goto('http://localhost:3000')
    
    // Run axe accessibility scan
    await page.addScriptTag({ 
      path: require.resolve('axe-core') 
    })
    
    const results = await page.evaluate(() => {
      return new Promise((resolve) => {
        axe.run((err, results) => {
          if (err) throw err
          resolve(results)
        })
      })
    })
    
    expect(results.violations).toHaveLength(0)
  })
  
  it('should be keyboard navigable', async () => {
    await page.goto('http://localhost:3000')
    
    // Tab through interactive elements
    await page.keyboard.press('Tab')
    const firstFocus = await page.evaluate(() => 
      document.activeElement.tagName
    )
    expect(['A', 'BUTTON', 'INPUT']).toContain(firstFocus)
    
    // Test skip links
    await page.keyboard.press('Enter')
    const mainContent = await page.$eval('#main-content', 
      el => el.getBoundingClientRect().top
    )
    expect(mainContent).toBeLessThan(100)
  })
})
```

## Cross-Browser Testing

### Browser Contexts
```javascript
describe('Cross-Browser Tests', () => {
  const browsers = ['chromium', 'firefox', 'webkit']
  
  browsers.forEach(browserType => {
    describe(`${browserType} tests`, () => {
      let browser, context, page
      
      beforeAll(async () => {
        browser = await playwright[browserType].launch()
        context = await browser.newContext()
        page = await context.newPage()
      })
      
      afterAll(async () => {
        await browser.close()
      })
      
      it('should render correctly', async () => {
        await page.goto('http://localhost:3000')
        const title = await page.title()
        expect(title).toBe('My Application')
      })
    })
  })
})
```

## Test Utilities

### Custom Helpers
```javascript
// helpers/ui-test-helpers.js
export const helpers = {
  // Wait for element and click
  async clickElement(page, selector) {
    await page.waitForSelector(selector, { visible: true })
    await page.click(selector)
  },
  
  // Fill form field
  async fillField(page, selector, value) {
    await page.waitForSelector(selector)
    await page.fill(selector, value)
  },
  
  // Wait for text
  async waitForText(page, text, options = {}) {
    await page.waitForFunction(
      text => document.body.textContent.includes(text),
      options,
      text
    )
  },
  
  // Take named screenshot
  async captureScreenshot(page, name) {
    await page.screenshot({
      path: `tests/screenshots/${name}-${Date.now()}.png`,
      fullPage: true
    })
  },
  
  // Mock API response
  async mockAPIResponse(page, url, response) {
    await page.route(url, route => {
      route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(response)
      })
    })
  }
}
```

## Network Interception

### API Mocking
```javascript
describe('API Integration Tests', () => {
  beforeEach(async () => {
    // Intercept API calls
    await page.route('**/api/users', route => {
      route.fulfill({
        status: 200,
        body: JSON.stringify([
          { id: 1, name: 'Test User' }
        ])
      })
    })
  })
  
  it('should display mocked users', async () => {
    await page.goto('http://localhost:3000/users')
    await page.waitForSelector('.user-list')
    
    const users = await page.$$eval('.user-item', 
      elements => elements.map(el => el.textContent)
    )
    expect(users).toContain('Test User')
  })
})
```

## Error Handling

### Robust Test Patterns
```javascript
describe('Error Handling Tests', () => {
  it('should handle network errors gracefully', async () => {
    // Simulate offline
    await page.setOfflineMode(true)
    
    await page.goto('http://localhost:3000/data')
    await page.waitForSelector('.error-message')
    
    const errorText = await page.$eval('.error-message', 
      el => el.textContent
    )
    expect(errorText).toContain('Unable to load data')
    
    // Restore connection
    await page.setOfflineMode(false)
  })
  
  it('should timeout gracefully', async () => {
    // Set short timeout
    page.setDefaultTimeout(1000)
    
    // Attempt action that will timeout
    await expect(
      page.waitForSelector('.non-existent', { timeout: 500 })
    ).rejects.toThrow('timeout')
  })
})
```

## Test Configuration

### Jest/Puppeteer Config
```javascript
// jest-puppeteer.config.js
module.exports = {
  launch: {
    headless: process.env.HEADLESS !== 'false',
    slowMo: process.env.SLOWMO ? parseInt(process.env.SLOWMO) : 0,
    devtools: process.env.DEVTOOLS === 'true',
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-dev-shm-usage'
    ]
  },
  server: {
    command: 'npm run start:test',
    port: 3000,
    launchTimeout: 10000,
    debug: true
  }
}
```

## Best Practices

### DO:
- ✅ Use Page Object Model for maintainability
- ✅ Test user journeys, not implementation
- ✅ Include accessibility testing
- ✅ Test responsive designs
- ✅ Mock external dependencies
- ✅ Use meaningful selectors (data-testid)
- ✅ Handle async operations properly
- ✅ Clean up after tests
- ✅ Take screenshots on failure
- ✅ Test error scenarios

### DON'T:
- ❌ Use brittle selectors
- ❌ Test third-party components
- ❌ Ignore timing issues
- ❌ Skip error scenarios
- ❌ Hardcode wait times
- ❌ Test styling details
- ❌ Forget cleanup
- ❌ Run tests in parallel without isolation
- ❌ Test implementation details
- ❌ Ignore flaky tests

## Debugging Tips

### Enable Debugging
```javascript
// Visual debugging
await page.screenshot({ path: 'debug.png' })
await page.pause() // Pauses execution

// Console logging
page.on('console', msg => console.log('PAGE LOG:', msg.text()))

// Network logging
page.on('request', request => 
  console.log('>>', request.method(), request.url())
)

// Slow motion mode
const browser = await puppeteer.launch({
  headless: false,
  slowMo: 250 // Slow down by 250ms
})
```

## Running Tests

```bash
# Run all UI tests
npm run test:ui

# Run specific test file
npm run test:ui -- login.test.js

# Run with debugging
HEADLESS=false npm run test:ui

# Run with slow motion
SLOWMO=250 npm run test:ui

# Generate coverage report
npm run test:ui:coverage
```