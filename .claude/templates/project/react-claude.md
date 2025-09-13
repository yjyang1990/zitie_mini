# {{project_name}} - React Application

Comprehensive development environment configuration for React application development with Claude Code and CCPM framework.

## Quick Start
```bash
# Most common commands
npm start                    # Start development server
npm test                     # Run tests in watch mode
npm run build               # Build for production
npm run lint                # Run ESLint
npm run format              # Format code with Prettier

# CCPM Framework
/pm:init                    # Initialize project management
/pm:status                  # Check project status
/testing:prime react        # Setup React testing environment
/testing:run                # Run comprehensive tests
```

## React Development Commands
```bash
# Development
npm start                   # Start development server (localhost:3000)
npm run dev                 # Alternative development command
npm run storybook           # Start Storybook (if configured)

# Testing
npm test                    # Jest tests in watch mode
npm run test:ci             # Jest tests for CI
npm run test:coverage       # Test coverage report
npm run test:e2e            # End-to-end tests (Cypress/Playwright)

# Code Quality
npm run lint                # ESLint checking
npm run lint:fix            # Auto-fix ESLint issues
npm run format              # Prettier formatting
npm run type-check          # TypeScript checking (if TS)

# Build and Deploy
npm run build               # Production build
npm run preview             # Preview production build
npm run analyze             # Bundle analyzer
npm run deploy              # Deploy to hosting platform
```

## Code Style Guidelines
- **Components**: Use functional components with hooks
- **State Management**: {{state_management}} (Context API, Redux, Zustand, etc.)
- **Styling**: {{styling_approach}} (CSS Modules, Styled Components, Tailwind, etc.)
- **Testing**: {{testing_framework}} with React Testing Library
- **TypeScript**: {{typescript_usage}} (if applicable)
- **File Organization**: Feature-based folder structure

## Project Structure
```
{{project_name}}/
├── public/                 # Static assets
├── src/
│   ├── components/         # Reusable UI components
│   │   ├── common/         # Common/shared components
│   │   └── specific/       # Feature-specific components
│   ├── pages/              # Page components (if using routing)
│   ├── hooks/              # Custom React hooks
│   ├── services/           # API services and external integrations
│   ├── utils/              # Utility functions
│   ├── types/              # TypeScript type definitions
│   ├── styles/             # Global styles and themes
│   ├── assets/             # Images, icons, fonts
│   └── __tests__/          # Test files
├── .claude/                # CCPM Framework
└── tests/                  # Additional test configurations
```

## Key Files to Know
- **src/App.jsx/tsx**: Main application component
- **src/index.jsx/tsx**: Application entry point
- **package.json**: Dependencies and scripts
- **src/components/**: Reusable component library
- **src/hooks/**: Custom React hooks
- **src/services/**: API and external service integrations

## Development Workflow (EPCC)

### 1. **Explore** - Understand the component ecosystem
- **Simple tasks**: Read component files directly
- **Complex features**: Use `frontend-engineer` agent for component architecture
- **State analysis**: Use `code-analyzer` agent for state flow tracing
- **Large components**: Use `file-analyzer` agent for component breakdown

### 2. **Plan** - Design component architecture
- Use **"think"** for component design decisions
- Use **"think hard"** for complex state management
- For major features: Use `ui-expert` agent for user experience design
- Create GitHub issues for component development

### 3. **Code** - Implement with React best practices
- **Simple components**: Direct file operations (Edit, Write tools)
- **Complex features**: Use specialized agents:
  - `frontend-engineer`: Component architecture, hooks, state management
  - `ui-expert`: User interface design and accessibility
  - `test-engineer`: Testing strategies for React components
- **Real testing**: Test against actual user interactions

### 4. **Commit** - Auto-generated commit messages
- Commits include context from component changes
- Use `github-specialist` agent for PR creation

## React-Specific Agents

### **frontend-engineer** (Primary)
- Component architecture and design patterns
- React hooks and state management
- Performance optimization
- Modern React patterns and best practices

### **ui-expert** (Secondary)
- User interface design and usability
- Responsive design implementation
- Accessibility compliance
- Design system integration

### **test-engineer** (Secondary)
- React Testing Library setup and usage
- Component testing strategies
- Integration testing with React
- End-to-end testing setup

## Testing Strategy
```bash
# Test Execution
npm test                     # Jest + React Testing Library
npm run test:coverage        # Coverage reports
npm run test:e2e             # End-to-end tests
npm run test:a11y            # Accessibility testing

# Test Development
# Write tests first for components (TDD approach)
# Focus on user behavior, not implementation details
# Use React Testing Library for user-centric testing
# Test accessibility with @testing-library/jest-dom
```

## Component Development Best Practices

### Component Structure
```jsx
// Component file structure
import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import styles from './ComponentName.module.css';

const ComponentName = ({ prop1, prop2, ...props }) => {
  // Hooks
  const [state, setState] = useState(initialValue);
  
  // Effects
  useEffect(() => {
    // Side effects
  }, [dependencies]);
  
  // Event handlers
  const handleEvent = (event) => {
    // Handle event
  };
  
  // Render
  return (
    <div className={styles.container} {...props}>
      {/* Component JSX */}
    </div>
  );
};

ComponentName.propTypes = {
  prop1: PropTypes.string.isRequired,
  prop2: PropTypes.number,
};

ComponentName.defaultProps = {
  prop2: 0,
};

export default ComponentName;
```

### State Management Patterns
- **Local State**: `useState` for component-level state
- **Global State**: {{state_management}} for application-wide state
- **Server State**: React Query/SWR for API data management
- **Form State**: Formik/React Hook Form for complex forms

### Performance Optimization
- Use `React.memo` for expensive components
- Implement `useMemo` and `useCallback` for optimization
- Code splitting with `React.lazy` and `Suspense`
- Bundle analysis for identifying optimization opportunities

## Tool Permissions
Pre-configured for React development:

**Always Allowed:**
- React development: npm, yarn commands
- Testing: Jest, React Testing Library, Cypress
- Code quality: ESLint, Prettier, TypeScript
- Build tools: Webpack, Vite, Create React App

**MCP Tools:** All configured MCP servers (filesystem, git, context7)

## Error Handling Philosophy
- **Component Error Boundaries** for graceful error handling
- **Graceful degradation** for optional features
- **User-friendly error messages** with actionable guidance
- **Development error overlay** for debugging

## Accessibility Standards
- Semantic HTML elements
- ARIA attributes where necessary
- Keyboard navigation support
- Screen reader compatibility
- Color contrast compliance (WCAG AA)

## Performance Targets
- **First Contentful Paint**: < 1.5s
- **Time to Interactive**: < 3s
- **Lighthouse Score**: > 90
- **Bundle Size**: < 250KB gzipped

## Browser Support
- Chrome (latest 2 versions)
- Firefox (latest 2 versions)
- Safari (latest 2 versions)
- Edge (latest 2 versions)
- Mobile browsers (iOS Safari, Chrome Mobile)

---

**IMPORTANT**: This CLAUDE.md is optimized for React development. The configuration includes React-specific commands, component architecture patterns, and frontend-focused development workflows. Use the CCPM framework commands to manage your React project efficiently.