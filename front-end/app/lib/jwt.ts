/**
 * Utility functions for JWT token handling
 */

export interface JWTPayload {
  userId: string;
  email: string;
  iat?: number;
  exp?: number;
}

/**
 * Decode JWT token without verification (client-side only)
 * Note: This doesn't verify the signature, just decodes the payload
 */
export function decodeJWT(token: string): JWTPayload | null {
  try {
    const base64Url = token.split('.')[1];
    if (!base64Url) return null;
    
    const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
    const jsonPayload = decodeURIComponent(
      atob(base64)
        .split('')
        .map((c) => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
        .join('')
    );
    
    return JSON.parse(jsonPayload);
  } catch (error) {
    console.error('Error decoding JWT:', error);
    return null;
  }
}

/**
 * Get user ID from stored access token
 */
export function getUserIdFromToken(): string | null {
  if (typeof window === 'undefined') return null;
  
  const token = localStorage.getItem('accessToken');
  if (!token) return null;
  
  const payload = decodeJWT(token);
  return payload?.userId || null;
}
