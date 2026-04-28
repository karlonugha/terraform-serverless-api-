// =============================================================================
// LAMBDA FUNCTION — URL Shortener
// =============================================================================
// This is the actual application code that runs inside Lambda.
//
// Lambda invokes the "handler" function every time an API request comes in.
// The function receives an "event" object containing the HTTP request details
// (method, path, body, headers) and returns a response object.
//
// Key Lambda concepts:
//   - Handler: the entry point function Lambda calls
//   - Event: the incoming request data
//   - Context: metadata about the invocation (timeout, request ID)
//   - Cold start: first invocation takes longer (loading the runtime)
//   - Warm invocation: subsequent calls reuse the same container (fast)
// =============================================================================

import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import {
  DynamoDBDocumentClient,
  PutCommand,
  GetCommand,
} from '@aws-sdk/lib-dynamodb';
import { randomBytes } from 'crypto';

// ---------------------------------------------------------------------------
// Initialize DynamoDB client OUTSIDE the handler.
// This runs once on cold start and is reused across warm invocations.
// This is a Lambda best practice — reuse connections between invocations.
// ---------------------------------------------------------------------------
const client = new DynamoDBClient({});
const dynamo = DynamoDBDocumentClient.from(client);

// Table name is passed via environment variable (set by Terraform)
const TABLE_NAME = process.env.TABLE_NAME;

// ---------------------------------------------------------------------------
// HANDLER — Lambda entry point
// ---------------------------------------------------------------------------
export const handler = async (event) => {
  console.log('Received event:', JSON.stringify(event, null, 2));

  const method = event.requestContext?.http?.method || event.httpMethod;
  const path = event.rawPath || event.path;

  try {
    // Health check
    if (path === '/health') {
      return response(200, { status: 'ok', service: 'url-shortener' });
    }

    // POST /shorten — create a short URL
    if (method === 'POST' && path === '/shorten') {
      return await createShortUrl(event);
    }

    // GET /{code} — redirect to original URL
    if (method === 'GET' && path !== '/shorten' && path !== '/') {
      const code = path.replace('/', '');
      return await redirectToUrl(code);
    }

    // Fallback
    return response(404, { error: 'Not found' });
  } catch (err) {
    console.error('Error:', err);
    return response(500, { error: 'Internal server error' });
  }
};

// ---------------------------------------------------------------------------
// CREATE SHORT URL
// ---------------------------------------------------------------------------
// Generates a random 6-character code, stores the mapping in DynamoDB,
// and returns the short URL.
// ---------------------------------------------------------------------------
async function createShortUrl(event) {
  const body = JSON.parse(event.body || '{}');

  if (!body.url) {
    return response(400, { error: 'Missing "url" in request body' });
  }

  // Validate URL format
  try {
    new URL(body.url);
  } catch {
    return response(400, { error: 'Invalid URL format' });
  }

  // Generate a random 6-character code
  const code = randomBytes(3).toString('hex'); // e.g., "a1b2c3"

  // Store in DynamoDB
  await dynamo.send(
    new PutCommand({
      TableName: TABLE_NAME,
      Item: {
        code,                          // Partition key
        originalUrl: body.url,
        createdAt: new Date().toISOString(),
        clicks: 0,
      },
    })
  );

  // Build the short URL using the API Gateway domain
  const domain = event.requestContext?.domainName || 'localhost';
  const shortUrl = `https://${domain}/${code}`;

  return response(201, {
    shortUrl,
    code,
    originalUrl: body.url,
  });
}

// ---------------------------------------------------------------------------
// REDIRECT TO ORIGINAL URL
// ---------------------------------------------------------------------------
// Looks up the code in DynamoDB and returns a 301 redirect.
// ---------------------------------------------------------------------------
async function redirectToUrl(code) {
  const result = await dynamo.send(
    new GetCommand({
      TableName: TABLE_NAME,
      Key: { code },
    })
  );

  if (!result.Item) {
    return response(404, { error: 'Short URL not found' });
  }

  // Return a 301 redirect — the browser follows this automatically
  return {
    statusCode: 301,
    headers: {
      Location: result.Item.originalUrl,
      'Cache-Control': 'no-cache',
    },
    body: '',
  };
}

// ---------------------------------------------------------------------------
// HELPER — Build HTTP response
// ---------------------------------------------------------------------------
function response(statusCode, body) {
  return {
    statusCode,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*', // CORS for browser access
    },
    body: JSON.stringify(body),
  };
}
