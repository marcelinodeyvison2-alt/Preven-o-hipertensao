export interface Track {
  id: string;
  title: string;
  artist: string;
  album: string;
  duration: number; // seconds
  artworkUrl: string;
  streamUrl: string;
}

export interface Playlist {
  id: string;
  name: string;
  tracks: Track[];
  createdAt: number;
}

export interface DownloadedTrack {
  track: Track;
  localUri: string;
  downloadedAt: number;
}

export type RepeatMode = 'off' | 'all' | 'one';
