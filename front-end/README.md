# Front-end Application

Next.js 14 web application providing the user interface for the microservices platform.

## Overview

The front-end application provides:
- User authentication (login/registration)
- User profile management
- Deposit functionality with Stripe integration
- Roulette game interface

## Port

- **Default**: 3003
- **Configurable**: Set `PORT` environment variable

## Technology Stack

- **Next.js 14** - React framework with App Router
- **React 18** - UI library
- **TypeScript** - Type safety
- **Tailwind CSS** - Styling
- **Axios** - HTTP client for API communication

## Installation

```bash
npm install
```

## Development

```bash
npm run dev
```

Starts the development server with hot-reload. The server will run on port 3003 by default, or the port specified in the `PORT` environment variable.

## Build

```bash
npm run build
```

Creates an optimized production build in the `.next` directory.

## Production

```bash
npm start
```

Starts the production server. Requires running `npm run build` first.

## Project Structure

```
front-end/
├── app/
│   ├── globals.css           # Global styles
│   ├── layout.tsx            # Root layout component
│   ├── page.tsx              # Home page
│   ├── login/
│   │   └── page.tsx          # Login page
│   ├── register/
│   │   └── page.tsx          # Registration page
│   ├── profile/
│   │   └── page.tsx          # User profile page
│   ├── roulette/
│   │   └── page.tsx          # Roulette game page
│   └── lib/
│       ├── api.ts            # API client utilities
│       └── jwt.ts            # JWT token management
├── public/                   # Static assets
├── next.config.js            # Next.js configuration
├── tailwind.config.ts       # Tailwind CSS configuration
└── tsconfig.json             # TypeScript configuration
```

## Pages

### Home Page (`/`)
Landing page with navigation to other sections.

### Login (`/login`)
User authentication page that:
- Accepts email and password
- Communicates with auth service
- Stores JWT tokens in browser
- Redirects to profile on success

### Registration (`/register`)
New user registration page that:
- Collects email and password
- Creates user account via API Gateway
- Handles validation errors
- Redirects to login on success

### Profile (`/profile`)
User profile page that displays:
- User information
- Current balance
- Deposit functionality
- Logout option

### Roulette (`/roulette`)
Roulette game interface (implementation may vary).

## API Integration

The front-end communicates with backend services through:

### API Client (`app/lib/api.ts`)
Centralized API client that:
- Handles base URL configuration
- Manages authentication headers
- Provides error handling
- Handles token refresh

### JWT Management (`app/lib/jwt.ts`)
Utilities for:
- Storing tokens in localStorage
- Retrieving tokens
- Token expiration checking

## Environment Variables

Create a `.env.local` file for local development:

```bash
NEXT_PUBLIC_API_URL=http://localhost:3002    # API Gateway URL
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_...  # Stripe publishable key
```

**Note**: Next.js requires the `NEXT_PUBLIC_` prefix for client-side environment variables.

## Styling

The application uses Tailwind CSS for styling:
- Utility-first CSS framework
- Responsive design
- Custom configuration in `tailwind.config.ts`
- Global styles in `app/globals.css`

## Authentication Flow

1. User logs in via `/login`
2. Frontend sends credentials to auth service
3. Receives JWT access token and refresh token
4. Stores tokens in localStorage
5. Includes access token in subsequent API requests
6. Refreshes token when expired (if implemented)

## Stripe Integration

For deposit functionality:
1. Frontend requests deposit creation from API Gateway
2. Receives Stripe PaymentIntent with client secret
3. Uses Stripe.js to complete payment
4. Updates user balance after successful payment

## Development Tips

### Hot Reload
Next.js provides fast refresh for instant updates during development.

### TypeScript
All components and utilities are typed for better developer experience and error catching.

### API Error Handling
The API client includes error handling, but you may want to add user-friendly error messages.

## Building for Production

1. **Set environment variables** in your deployment platform
2. **Build the application:**
   ```bash
   npm run build
   ```
3. **Start the production server:**
   ```bash
   npm start
   ```

## Deployment

The front-end can be deployed to:
- **Vercel** (recommended for Next.js)
- **Netlify**
- **Docker container**
- **Any Node.js hosting**

### Docker Example

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build
EXPOSE 3003
CMD ["npm", "start"]
```

## Dependencies

- **next** - Next.js framework
- **react** - React library
- **react-dom** - React DOM renderer
- **axios** - HTTP client
- **typescript** - TypeScript support
- **tailwindcss** - CSS framework
- **autoprefixer** - CSS post-processing
- **postcss** - CSS transformation

## Linting

```bash
npm run lint
```

Runs ESLint to check code quality and catch potential errors.

## Browser Support

The application supports modern browsers:
- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)

## Security Considerations

- JWT tokens stored in localStorage (consider httpOnly cookies for production)
- API calls should use HTTPS in production
- Validate all user inputs
- Implement CSRF protection if needed
- Rate limiting should be handled by backend services

## Troubleshooting

### Port Already in Use
Change the port:
```bash
PORT=3004 npm run dev
```

### API Connection Issues
- Verify API Gateway is running
- Check `NEXT_PUBLIC_API_URL` environment variable
- Verify CORS configuration on backend

### Build Errors
- Clear `.next` directory: `rm -rf .next`
- Reinstall dependencies: `rm -rf node_modules && npm install`
- Check TypeScript errors: `npx tsc --noEmit`
