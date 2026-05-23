import { Request, Response } from 'express';
import axios from 'axios';

export async function proxyDirections(req: Request, res: Response) {
  const { origin, destination, mode } = req.query;
  if (!origin || !destination) {
    return res.status(400).json({ error: 'origin and destination are required.' });
  }

  try {
    const apiKey = process.env.MAPS_API_KEY || 'mock-backend-maps-api-key';
    const response = await axios.get(
      'https://maps.googleapis.com/maps/api/directions/json',
      { params: { origin, destination, mode: mode || 'walking', key: apiKey } }
    );
    return res.status(200).json(response.data);
  } catch (error) {
    return res.status(500).json({
      error: error instanceof Error ? error.message : 'Directions API proxy failed'
    });
  }
}

export async function proxyGeocode(req: Request, res: Response) {
  const { address } = req.query;
  if (!address) {
    return res.status(400).json({ error: 'address is required.' });
  }

  try {
    const apiKey = process.env.MAPS_API_KEY || 'mock-backend-maps-api-key';
    const response = await axios.get(
      'https://maps.googleapis.com/maps/api/geocode/json',
      { params: { address, key: apiKey } }
    );
    return res.status(200).json(response.data);
  } catch (error) {
    return res.status(500).json({
      error: error instanceof Error ? error.message : 'Geocoding API proxy failed'
    });
  }
}

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
