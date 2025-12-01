# Casino Frontend

A Next.js frontend application for the casino microservices platform.

## Features

- Landing page with login/register buttons
- Login page
- Registration page
- Roulette game page with balance input and bet button

## Getting Started

### Install Dependencies

```bash
npm install
```

### Run Development Server

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

### Environment Variables

Create a `.env.local` file:

```
NEXT_PUBLIC_API_URL=http://localhost:3001
NEXT_PUBLIC_GATEWAY_URL=http://localhost:3002
```

## Build for Production

```bash
npm run build
npm start
```
