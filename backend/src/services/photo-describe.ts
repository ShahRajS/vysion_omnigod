import { Request, Response } from 'express';
import axios from 'axios';

const GEMINI_API_URL =
  process.env.GEMINI_API_URL ||
  'https://generativelanguage.googleapis.com/v1beta2/models/gemini-1.5-image-preview:generate';
const TTS_API_URL =
  process.env.TTS_API_URL ||
  'https://texttospeech.googleapis.com/v1/text:synthesize';
const API_KEY = process.env.GEMINI_API_KEY || process.env.TTS_API_KEY;

function parseGeminiDescription(responseData: any): string {
  if (!responseData) return '';

  if (typeof responseData.outputText === 'string') {
    return responseData.outputText;
  }

  if (Array.isArray(responseData.candidates) && responseData.candidates.length) {
    const candidate = responseData.candidates[0];
    if (typeof candidate.content === 'string') {
      return candidate.content;
    }
  }

  if (Array.isArray(responseData.output) && responseData.output.length) {
    const first = responseData.output[0];
    if (typeof first === 'string') {
      return first;
    }
    if (Array.isArray(first) && first.length && typeof first[0] === 'string') {
      return first[0];
    }
  }

  return '';
}

async function describeImageWithGemini(imageBytes: Buffer): Promise<string> {
  if (!API_KEY) {
    throw new Error('Missing GEMINI_API_KEY or TTS_API_KEY in environment');
  }

  const requestBody = {
    prompt: {
      messages: [
        {
          role: 'user',
          content: [
            {
              type: 'image',
              image: {
                imageBytes: imageBytes.toString('base64'),
              },
            },
            {
              type: 'text',
              text: 'Describe the content of this image in one concise sentence.',
            },
          ],
        },
      ],
    },
    temperature: 0.2,
    maxOutputTokens: 150,
  };

  const response = await axios.post(GEMINI_API_URL, requestBody, {
    params: {
      key: API_KEY,
    },
    headers: {
      'Content-Type': 'application/json',
    },
    timeout: 30000,
  });

  const description = parseGeminiDescription(response.data);
  if (!description) {
    throw new Error('Gemini response did not include a valid description');
  }

  return description;
}

async function synthesizeTextToMp3(text: string): Promise<Buffer> {
  if (!API_KEY) {
    throw new Error('Missing GEMINI_API_KEY or TTS_API_KEY in environment');
  }

  const response = await axios.post(
    `${TTS_API_URL}?key=${API_KEY}`,
    {
      input: { text },
      voice: {
        languageCode: 'en-US',
        name: 'en-US-Wavenet-F',
      },
      audioConfig: {
        audioEncoding: 'MP3',
      },
    },
    {
      headers: {
        'Content-Type': 'application/json',
      },
      timeout: 30000,
    },
  );

  if (!response.data?.audioContent) {
    throw new Error('Text-to-Speech response did not return audio content');
  }

  return Buffer.from(response.data.audioContent, 'base64');
}

export async function describePhoto(req: Request, res: Response) {
  if (!Buffer.isBuffer(req.body) || req.body.length === 0) {
    return res.status(400).json({
      error: 'Request body must be raw image bytes',
    });
  }

  const imageBytes = req.body as Buffer;

  try {
    const description = await describeImageWithGemini(imageBytes);
    const audioBuffer = await synthesizeTextToMp3(description);

    res.setHeader('Content-Type', 'audio/mpeg');
    res.setHeader('X-Description', description);
    res.send(audioBuffer);
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    return res.status(500).json({
      error: 'Photo describe pipeline failed',
      details: message,
    });
  }
}
