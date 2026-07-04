import React, { useState } from 'react';
import { View, Text, Image, Pressable, StyleSheet, SafeAreaView } from 'react-native';
import Slider from '@react-native-community/slider';
import { Ionicons } from '@expo/vector-icons';
import { usePlayer } from '../contexts/PlayerContext';
import { useLibrary } from '../contexts/LibraryContext';
import AddToPlaylistModal from '../components/AddToPlaylistModal';

function formatTime(seconds: number): string {
  if (!Number.isFinite(seconds) || seconds < 0) return '0:00';
  const mins = Math.floor(seconds / 60);
  const secs = Math.floor(seconds % 60);
  return `${mins}:${secs.toString().padStart(2, '0')}`;
}

export default function PlayerScreen({ navigation }: any) {
  const {
    currentTrack,
    isPlaying,
    isBuffering,
    currentTime,
    duration,
    repeatMode,
    shuffle,
    togglePlayPause,
    playNext,
    playPrevious,
    seekTo,
    toggleShuffle,
    cycleRepeatMode,
  } = usePlayer();
  const { isFavorite, toggleFavorite, isDownloaded, downloadTrack, downloadingIds } = useLibrary();
  const [showPlaylistModal, setShowPlaylistModal] = useState(false);
  const [seekValue, setSeekValue] = useState<number | null>(null);

  if (!currentTrack) {
    return (
      <SafeAreaView style={styles.container}>
        <Text style={styles.emptyText}>Nada tocando no momento.</Text>
      </SafeAreaView>
    );
  }

  const downloadProgress = downloadingIds[currentTrack.id];
  const favorite = isFavorite(currentTrack.id);
  const downloaded = isDownloaded(currentTrack.id);

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.topBar}>
        <Pressable onPress={() => navigation.goBack()} hitSlop={12}>
          <Ionicons name="chevron-down" size={28} color="#fff" />
        </Pressable>
        <Text style={styles.topBarTitle}>Tocando agora</Text>
        <Pressable onPress={() => setShowPlaylistModal(true)} hitSlop={12}>
          <Ionicons name="ellipsis-horizontal" size={24} color="#fff" />
        </Pressable>
      </View>

      <Image source={{ uri: currentTrack.artworkUrl }} style={styles.artwork} />

      <View style={styles.infoRow}>
        <View style={{ flex: 1 }}>
          <Text style={styles.title} numberOfLines={1}>
            {currentTrack.title}
          </Text>
          <Text style={styles.artist} numberOfLines={1}>
            {currentTrack.artist}
          </Text>
        </View>
        <Pressable onPress={() => toggleFavorite(currentTrack)} hitSlop={10}>
          <Ionicons name={favorite ? 'heart' : 'heart-outline'} size={26} color={favorite ? '#1DB954' : '#fff'} />
        </Pressable>
        <Pressable
          onPress={() => downloadProgress === undefined && downloadTrack(currentTrack)}
          hitSlop={10}
          style={{ marginLeft: 16 }}
        >
          <Ionicons
            name={downloaded ? 'checkmark-circle' : 'download-outline'}
            size={24}
            color={downloaded ? '#1DB954' : '#fff'}
          />
        </Pressable>
      </View>

      <Slider
        style={styles.slider}
        minimumValue={0}
        maximumValue={Math.max(duration, 1)}
        value={seekValue ?? currentTime}
        onSlidingStart={(v) => setSeekValue(v)}
        onSlidingComplete={(v) => {
          seekTo(v);
          setSeekValue(null);
        }}
        minimumTrackTintColor="#1DB954"
        maximumTrackTintColor="#444"
        thumbTintColor="#1DB954"
      />
      <View style={styles.timeRow}>
        <Text style={styles.time}>{formatTime(seekValue ?? currentTime)}</Text>
        <Text style={styles.time}>{formatTime(duration)}</Text>
      </View>

      <View style={styles.controlsRow}>
        <Pressable onPress={toggleShuffle} hitSlop={10}>
          <Ionicons name="shuffle" size={22} color={shuffle ? '#1DB954' : '#888'} />
        </Pressable>
        <Pressable onPress={playPrevious} hitSlop={10}>
          <Ionicons name="play-skip-back" size={32} color="#fff" />
        </Pressable>
        <Pressable onPress={togglePlayPause} style={styles.playButton} hitSlop={10}>
          <Ionicons name={isBuffering ? 'hourglass' : isPlaying ? 'pause' : 'play'} size={32} color="#000" />
        </Pressable>
        <Pressable onPress={playNext} hitSlop={10}>
          <Ionicons name="play-skip-forward" size={32} color="#fff" />
        </Pressable>
        <Pressable onPress={cycleRepeatMode} hitSlop={10}>
          <Ionicons
            name={repeatMode === 'one' ? 'repeat' : 'repeat'}
            size={22}
            color={repeatMode === 'off' ? '#888' : '#1DB954'}
          />
          {repeatMode === 'one' && <View style={styles.repeatOneDot} />}
        </Pressable>
      </View>

      <AddToPlaylistModal
        visible={showPlaylistModal}
        track={currentTrack}
        onClose={() => setShowPlaylistModal(false)}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#121212',
    paddingHorizontal: 24,
  },
  emptyText: {
    color: '#9b9b9b',
    textAlign: 'center',
    marginTop: 80,
  },
  topBar: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingTop: 8,
  },
  topBarTitle: {
    color: '#fff',
    fontSize: 13,
    fontWeight: '600',
    textTransform: 'uppercase',
    letterSpacing: 1,
  },
  artwork: {
    width: '100%',
    aspectRatio: 1,
    borderRadius: 12,
    backgroundColor: '#222',
    marginTop: 32,
  },
  infoRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 28,
  },
  title: {
    color: '#fff',
    fontSize: 20,
    fontWeight: '800',
  },
  artist: {
    color: '#9b9b9b',
    fontSize: 15,
    marginTop: 4,
  },
  slider: {
    width: '100%',
    height: 32,
    marginTop: 20,
  },
  timeRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: -6,
  },
  time: {
    color: '#9b9b9b',
    fontSize: 12,
  },
  controlsRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginTop: 32,
  },
  playButton: {
    backgroundColor: '#fff',
    width: 64,
    height: 64,
    borderRadius: 32,
    alignItems: 'center',
    justifyContent: 'center',
  },
  repeatOneDot: {
    position: 'absolute',
    top: -2,
    right: -2,
    width: 6,
    height: 6,
    borderRadius: 3,
    backgroundColor: '#1DB954',
  },
});
