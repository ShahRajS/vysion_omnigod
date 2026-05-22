import { Request, Response } from 'express';
import axios from 'axios';

/**
 * Proxy places queries to Google Places API using server-restricted key.
 */
export async function proxyPlacesSearch(req: Request, res: Response) {
  const { query } = req.body;
  if (!query) {
    return res.status(400).json({ error: 'Query parameter is required.' });
  }

  try {
    const apiKey = process.env.MAPS_API_KEY || 'mock-backend-maps-api-key';
    
    // Fallback Mock during development or unit testing
    if (apiKey === 'mock-backend-maps-api-key' || process.env.NODE_ENV === 'test') {
      return res.status(200).json([
        {
          name: 'Starbucks Coffee',
          formatted_address: '123 Main St, Boston, MA 02111',
          geometry: {
            location: { lat: 42.3512, lng: -71.0589 }
          }
        }
      ]);
    }

    const response = await axios.get(
      'https://maps.googleapis.com/maps/api/place/textsearch/json',
      {
        params: {
          query,
          key: apiKey
        }
      }
    );

    if (response.data.status === 'OK') {
      return res.status(200).json(response.data.results);
    } else {
      return res.status(500).json({
        error: `Places API Status Error: ${response.data.status}`,
        details: response.data
      });
    }
  } catch (error) {
    return res.status(500).json({
      error: error instanceof Error ? error.message : 'Failed to query Places API proxy'
    });
  }
}
