import React, { createContext, useContext, useEffect, useMemo, useState, useCallback } from 'react';
import { useAuth } from './AuthContext';
import { getItem, setItem } from '../services/storage';
import * as downloadManager from '../services/downloadManager';
import { DownloadedTrack, Playlist, Track } from '../types';

interface LibraryContextValue {
  favorites: Track[];
  isFavorite: (trackId: string) => boolean;
  toggleFavorite: (track: Track) => void;
  playlists: Playlist[];
  createPlaylist: (name: string) => Playlist;
  deletePlaylist: (playlistId: string) => void;
  addToPlaylist: (playlistId: string, track: Track) => void;
  removeFromPlaylist: (playlistId: string, trackId: string) => void;
  downloads: DownloadedTrack[];
  downloadingIds: Record<string, number>;
  isDownloaded: (trackId: string) => boolean;
  getLocalUri: (trackId: string) => string | undefined;
  downloadTrack: (track: Track) => Promise<void>;
  removeDownload: (trackId: string) => Promise<void>;
  loading: boolean;
}

const LibraryContext = createContext<LibraryContextValue | undefined>(undefined);

function favoritesKey(uid: string) {
  return `favorites:${uid}`;
}
function playlistsKey(uid: string) {
  return `playlists:${uid}`;
}

export function LibraryProvider({ children }: { children: React.ReactNode }) {
  const { user } = useAuth();
  const uid = user?.uid ?? 'guest';

  const [favorites, setFavorites] = useState<Track[]>([]);
  const [playlists, setPlaylists] = useState<Playlist[]>([]);
  const [downloads, setDownloads] = useState<DownloadedTrack[]>([]);
  const [downloadingIds, setDownloadingIds] = useState<Record<string, number>>({});
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    (async () => {
      const [favs, lists, dls] = await Promise.all([
        getItem<Track[]>(favoritesKey(uid)),
        getItem<Playlist[]>(playlistsKey(uid)),
        downloadManager.getDownloads(uid),
      ]);
      if (cancelled) return;
      setFavorites(favs ?? []);
      setPlaylists(lists ?? []);
      setDownloads(dls);
      setLoading(false);
    })();
    return () => {
      cancelled = true;
    };
  }, [uid]);

  const isFavorite = useCallback(
    (trackId: string) => favorites.some((t) => t.id === trackId),
    [favorites]
  );

  const toggleFavorite = useCallback(
    (track: Track) => {
      setFavorites((prev) => {
        const exists = prev.some((t) => t.id === track.id);
        const next = exists ? prev.filter((t) => t.id !== track.id) : [track, ...prev];
        setItem(favoritesKey(uid), next);
        return next;
      });
    },
    [uid]
  );

  const createPlaylist = useCallback(
    (name: string) => {
      const playlist: Playlist = {
        id: `${Date.now()}`,
        name: name.trim() || 'Nova playlist',
        tracks: [],
        createdAt: Date.now(),
      };
      setPlaylists((prev) => {
        const next = [playlist, ...prev];
        setItem(playlistsKey(uid), next);
        return next;
      });
      return playlist;
    },
    [uid]
  );

  const deletePlaylist = useCallback(
    (playlistId: string) => {
      setPlaylists((prev) => {
        const next = prev.filter((p) => p.id !== playlistId);
        setItem(playlistsKey(uid), next);
        return next;
      });
    },
    [uid]
  );

  const addToPlaylist = useCallback(
    (playlistId: string, track: Track) => {
      setPlaylists((prev) => {
        const next = prev.map((p) =>
          p.id === playlistId && !p.tracks.some((t) => t.id === track.id)
            ? { ...p, tracks: [...p.tracks, track] }
            : p
        );
        setItem(playlistsKey(uid), next);
        return next;
      });
    },
    [uid]
  );

  const removeFromPlaylist = useCallback(
    (playlistId: string, trackId: string) => {
      setPlaylists((prev) => {
        const next = prev.map((p) =>
          p.id === playlistId ? { ...p, tracks: p.tracks.filter((t) => t.id !== trackId) } : p
        );
        setItem(playlistsKey(uid), next);
        return next;
      });
    },
    [uid]
  );

  const isDownloaded = useCallback(
    (trackId: string) => downloads.some((d) => d.track.id === trackId),
    [downloads]
  );

  const getLocalUri = useCallback(
    (trackId: string) => downloads.find((d) => d.track.id === trackId)?.localUri,
    [downloads]
  );

  const downloadTrack = useCallback(
    async (track: Track) => {
      setDownloadingIds((prev) => ({ ...prev, [track.id]: 0 }));
      try {
        const entry = await downloadManager.downloadTrack(uid, track, (progress) => {
          setDownloadingIds((prev) => ({ ...prev, [track.id]: progress }));
        });
        setDownloads((prev) => [...prev.filter((d) => d.track.id !== track.id), entry]);
      } finally {
        setDownloadingIds((prev) => {
          const next = { ...prev };
          delete next[track.id];
          return next;
        });
      }
    },
    [uid]
  );

  const removeDownload = useCallback(
    async (trackId: string) => {
      await downloadManager.deleteDownload(uid, trackId);
      setDownloads((prev) => prev.filter((d) => d.track.id !== trackId));
    },
    [uid]
  );

  const value = useMemo<LibraryContextValue>(
    () => ({
      favorites,
      isFavorite,
      toggleFavorite,
      playlists,
      createPlaylist,
      deletePlaylist,
      addToPlaylist,
      removeFromPlaylist,
      downloads,
      downloadingIds,
      isDownloaded,
      getLocalUri,
      downloadTrack,
      removeDownload,
      loading,
    }),
    [
      favorites,
      isFavorite,
      toggleFavorite,
      playlists,
      createPlaylist,
      deletePlaylist,
      addToPlaylist,
      removeFromPlaylist,
      downloads,
      downloadingIds,
      isDownloaded,
      getLocalUri,
      downloadTrack,
      removeDownload,
      loading,
    ]
  );

  return <LibraryContext.Provider value={value}>{children}</LibraryContext.Provider>;
}

export function useLibrary(): LibraryContextValue {
  const ctx = useContext(LibraryContext);
  if (!ctx) throw new Error('useLibrary deve ser usado dentro de LibraryProvider');
  return ctx;
}
