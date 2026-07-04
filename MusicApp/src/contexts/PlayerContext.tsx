import React, { createContext, useContext, useEffect, useMemo, useRef, useState, useCallback } from 'react';
import { useAudioPlayer, useAudioPlayerStatus, setAudioModeAsync } from 'expo-audio';
import { useLibrary } from './LibraryContext';
import { RepeatMode, Track } from '../types';

interface PlayerContextValue {
  queue: Track[];
  currentTrack: Track | null;
  currentIndex: number;
  isPlaying: boolean;
  isBuffering: boolean;
  currentTime: number;
  duration: number;
  repeatMode: RepeatMode;
  shuffle: boolean;
  playQueue: (tracks: Track[], startIndex?: number) => void;
  playTrack: (track: Track) => void;
  togglePlayPause: () => void;
  playNext: () => void;
  playPrevious: () => void;
  seekTo: (seconds: number) => void;
  toggleShuffle: () => void;
  cycleRepeatMode: () => void;
}

const PlayerContext = createContext<PlayerContextValue | undefined>(undefined);

setAudioModeAsync({
  playsInSilentMode: true,
  shouldPlayInBackground: true,
  interruptionMode: 'duckOthers',
}).catch(() => {
  // best-effort; playback still works with default audio mode
});

export function PlayerProvider({ children }: { children: React.ReactNode }) {
  const { getLocalUri } = useLibrary();
  const player = useAudioPlayer(null, { updateInterval: 500 });
  const status = useAudioPlayerStatus(player);

  const [queue, setQueue] = useState<Track[]>([]);
  const [currentIndex, setCurrentIndex] = useState(-1);
  const [repeatMode, setRepeatMode] = useState<RepeatMode>('off');
  const [shuffle, setShuffle] = useState(false);
  const handledFinishRef = useRef(false);

  const currentTrack = currentIndex >= 0 ? queue[currentIndex] ?? null : null;

  const loadAndPlay = useCallback(
    (track: Track) => {
      const localUri = getLocalUri(track.id);
      player.replace(localUri ?? track.streamUrl);
      handledFinishRef.current = false;
      player.play();
    },
    [getLocalUri, player]
  );

  const playQueue = useCallback(
    (tracks: Track[], startIndex = 0) => {
      if (tracks.length === 0) return;
      setQueue(tracks);
      setCurrentIndex(startIndex);
      loadAndPlay(tracks[startIndex]);
    },
    [loadAndPlay]
  );

  const playTrack = useCallback(
    (track: Track) => {
      playQueue([track], 0);
    },
    [playQueue]
  );

  const togglePlayPause = useCallback(() => {
    if (status.playing) {
      player.pause();
    } else {
      player.play();
    }
  }, [player, status.playing]);

  const goToIndex = useCallback(
    (index: number) => {
      if (index < 0 || index >= queue.length) return;
      setCurrentIndex(index);
      loadAndPlay(queue[index]);
    },
    [queue, loadAndPlay]
  );

  const playNext = useCallback(() => {
    if (queue.length === 0) return;
    if (shuffle) {
      const next = Math.floor(Math.random() * queue.length);
      goToIndex(next);
      return;
    }
    const isLast = currentIndex >= queue.length - 1;
    if (isLast) {
      if (repeatMode === 'all') goToIndex(0);
      return;
    }
    goToIndex(currentIndex + 1);
  }, [queue, shuffle, currentIndex, repeatMode, goToIndex]);

  const playPrevious = useCallback(() => {
    if (queue.length === 0) return;
    if (status.currentTime > 3) {
      player.seekTo(0);
      return;
    }
    goToIndex(Math.max(0, currentIndex - 1));
  }, [queue, currentIndex, goToIndex, player, status.currentTime]);

  const seekTo = useCallback(
    (seconds: number) => {
      player.seekTo(seconds);
    },
    [player]
  );

  const toggleShuffle = useCallback(() => setShuffle((prev) => !prev), []);

  const cycleRepeatMode = useCallback(() => {
    setRepeatMode((prev) => (prev === 'off' ? 'all' : prev === 'all' ? 'one' : 'off'));
  }, []);

  // Auto-advance when a track finishes playing.
  useEffect(() => {
    if (!status.didJustFinish || handledFinishRef.current) return;
    handledFinishRef.current = true;
    if (repeatMode === 'one') {
      player.seekTo(0);
      player.play();
    } else {
      playNext();
    }
  }, [status.didJustFinish, repeatMode, playNext, player]);

  const value = useMemo<PlayerContextValue>(
    () => ({
      queue,
      currentTrack,
      currentIndex,
      isPlaying: status.playing,
      isBuffering: status.isBuffering,
      currentTime: status.currentTime,
      duration: status.duration,
      repeatMode,
      shuffle,
      playQueue,
      playTrack,
      togglePlayPause,
      playNext,
      playPrevious,
      seekTo,
      toggleShuffle,
      cycleRepeatMode,
    }),
    [
      queue,
      currentTrack,
      currentIndex,
      status.playing,
      status.isBuffering,
      status.currentTime,
      status.duration,
      repeatMode,
      shuffle,
      playQueue,
      playTrack,
      togglePlayPause,
      playNext,
      playPrevious,
      seekTo,
      toggleShuffle,
      cycleRepeatMode,
    ]
  );

  return <PlayerContext.Provider value={value}>{children}</PlayerContext.Provider>;
}

export function usePlayer(): PlayerContextValue {
  const ctx = useContext(PlayerContext);
  if (!ctx) throw new Error('usePlayer deve ser usado dentro de PlayerProvider');
  return ctx;
}
