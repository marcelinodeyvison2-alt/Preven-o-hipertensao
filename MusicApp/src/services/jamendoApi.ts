import axios from 'axios';
import { JAMENDO_BASE_URL, JAMENDO_CLIENT_ID } from '../config/jamendo';
import { Track } from '../types';

const client = axios.create({ baseURL: JAMENDO_BASE_URL, timeout: 15000 });

interface JamendoTrack {
  id: string;
  name: string;
  artist_name: string;
  album_name: string;
  duration: number;
  image: string;
  audio: string;
}

function mapTrack(raw: JamendoTrack): Track {
  return {
    id: raw.id,
    title: raw.name,
    artist: raw.artist_name,
    album: raw.album_name,
    duration: raw.duration,
    artworkUrl: raw.image,
    streamUrl: raw.audio,
  };
}

async function fetchTracks(params: Record<string, string | number>): Promise<Track[]> {
  if (!JAMENDO_CLIENT_ID) {
    throw new Error(
      'Falta configurar EXPO_PUBLIC_JAMENDO_CLIENT_ID no arquivo .env (veja .env.example).'
    );
  }
  const { data } = await client.get('/tracks/', {
    params: {
      client_id: JAMENDO_CLIENT_ID,
      format: 'json',
      include: 'musicinfo',
      audioformat: 'mp32',
      ...params,
    },
  });
  return (data.results as JamendoTrack[]).map(mapTrack);
}

export function getPopularTracks(limit = 30): Promise<Track[]> {
  return fetchTracks({ order: 'popularity_total', limit });
}

export function getTracksByTag(tag: string, limit = 30): Promise<Track[]> {
  return fetchTracks({ tags: tag, order: 'popularity_total', limit });
}

export function searchTracks(query: string, limit = 30): Promise<Track[]> {
  return fetchTracks({ namesearch: query, limit });
}

export const GENRES = [
  'pop',
  'rock',
  'electronic',
  'hiphop',
  'jazz',
  'classical',
  'metal',
  'folk',
  'reggae',
  'ambient',
  'lounge',
  'soundtrack',
];
