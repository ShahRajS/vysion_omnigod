import { Request, Response } from 'express';
import axios from 'axios';

const GEMINI_API_URL =
  process.env.GEMINI_API_URL ||
  'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';
const API_KEY = process.env.GEMINI_API_KEY;

function parseGeminiDescription(responseData: any): string {
  const parts = responseData?.candidates?.[0]?.content?.parts;
  if (!Array.isArray(parts)) return '';

  return parts
    .map((part: any) => part.text)
    .filter((text: any) => typeof text === 'string')
    .join(' ')
    .trim();
}

async function describeImageWithGemini(imageBytes: Buffer): Promise<string> {
  if (!API_KEY) {
    throw new Error('Missing GEMINI_API_KEY in environment');
  }

  const requestBody = {
    contents: [
      {
        parts: [
          {
            inline_data: {
              mime_type: 'image/jpeg',
              data: imageBytes.toString('base64'),
            },
          },
          {
            text:
              'Describe this image for a blind or low-vision user in one clear, helpful sentence. ' +
              'Mention important objects, people, text, hazards, and spatial layout if visible.',
          },
        ],
      },
    ],
    generationConfig: {
      temperature: 0.2,
      maxOutputTokens: 120,
    },
  };

  const response = await axios.post(GEMINI_API_URL, requestBody, {
    headers: {
      'Content-Type': 'application/json',
      'x-goog-api-key': API_KEY,
    },
    timeout: 30000,
  });

  const description = parseGeminiDescription(response.data);
  if (!description) {
    throw new Error('Gemini response did not include a valid description');
  }

  return description;
}

export async function describePhoto(req: Request, res: Response) {
  if (!Buffer.isBuffer(req.body) || req.body.length === 0) {
    return res.status(400).json({
      error: 'Request body must be raw image bytes',
    });
  }

  try {
    const description = await describeImageWithGemini(req.body as Buffer);
    res.status(200).json({ description });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    return res.status(500).json({
      error: 'Photo describe pipeline failed',
      details: message,
    });
  }
}
