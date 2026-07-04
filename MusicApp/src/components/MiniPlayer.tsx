import React from 'react';
import { Image, Pressable, StyleSheet, Text, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useNavigation } from '@react-navigation/native';
import { usePlayer } from '../contexts/PlayerContext';

export default function MiniPlayer() {
  const { currentTrack, isPlaying, isBuffering, togglePlayPause, playNext, currentTime, duration } = usePlayer();
  const navigation = useNavigation<any>();

  if (!currentTrack) return null;

  const progress = duration > 0 ? currentTime / duration : 0;

  return (
    <Pressable style={styles.container} onPress={() => navigation.navigate('Player')}>
      <View style={styles.progressTrack}>
        <View style={[styles.progressFill, { width: `${Math.min(progress * 100, 100)}%` }]} />
      </View>
      <View style={styles.content}>
        <Image source={{ uri: currentTrack.artworkUrl }} style={styles.artwork} />
        <View style={styles.info}>
          <Text style={styles.title} numberOfLines={1}>
            {currentTrack.title}
          </Text>
          <Text style={styles.artist} numberOfLines={1}>
            {currentTrack.artist}
          </Text>
        </View>
        <Pressable hitSlop={10} onPress={togglePlayPause} style={styles.button}>
          <Ionicons name={isBuffering ? 'ellipsis-horizontal' : isPlaying ? 'pause' : 'play'} size={24} color="#fff" />
        </Pressable>
        <Pressable hitSlop={10} onPress={playNext} style={styles.button}>
          <Ionicons name="play-skip-forward" size={22} color="#fff" />
        </Pressable>
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  container: {
    position: 'absolute',
    left: 8,
    right: 8,
    bottom: 58,
    backgroundColor: '#2a2a2a',
    borderRadius: 8,
    overflow: 'hidden',
    elevation: 6,
  },
  progressTrack: {
    height: 2,
    backgroundColor: '#444',
    width: '100%',
  },
  progressFill: {
    height: 2,
    backgroundColor: '#1DB954',
  },
  content: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 8,
  },
  artwork: {
    width: 40,
    height: 40,
    borderRadius: 4,
    backgroundColor: '#222',
  },
  info: {
    flex: 1,
    marginLeft: 10,
  },
  title: {
    color: '#fff',
    fontSize: 14,
    fontWeight: '600',
  },
  artist: {
    color: '#bbb',
    fontSize: 12,
    marginTop: 1,
  },
  button: {
    paddingHorizontal: 8,
  },
});
