import React from 'react';
import { Image, Pressable, StyleSheet, Text, View, ActivityIndicator } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Track } from '../types';

interface TrackRowProps {
  track: Track;
  isActive?: boolean;
  isFavorite?: boolean;
  isDownloaded?: boolean;
  downloadProgress?: number;
  onPress: () => void;
  onToggleFavorite?: () => void;
  onDownload?: () => void;
  onMore?: () => void;
}

export default function TrackRow({
  track,
  isActive,
  isFavorite,
  isDownloaded,
  downloadProgress,
  onPress,
  onToggleFavorite,
  onDownload,
  onMore,
}: TrackRowProps) {
  return (
    <Pressable style={styles.row} onPress={onPress}>
      <Image source={{ uri: track.artworkUrl }} style={styles.artwork} />
      <View style={styles.info}>
        <Text style={[styles.title, isActive && styles.activeText]} numberOfLines={1}>
          {track.title}
        </Text>
        <Text style={styles.artist} numberOfLines={1}>
          {track.artist}
        </Text>
      </View>
      {onToggleFavorite && (
        <Pressable hitSlop={10} onPress={onToggleFavorite} style={styles.iconButton}>
          <Ionicons name={isFavorite ? 'heart' : 'heart-outline'} size={20} color={isFavorite ? '#1DB954' : '#aaa'} />
        </Pressable>
      )}
      {onDownload &&
        (downloadProgress !== undefined ? (
          <View style={styles.iconButton}>
            <ActivityIndicator size="small" color="#1DB954" />
          </View>
        ) : (
          <Pressable hitSlop={10} onPress={onDownload} style={styles.iconButton}>
            <Ionicons
              name={isDownloaded ? 'checkmark-circle' : 'download-outline'}
              size={20}
              color={isDownloaded ? '#1DB954' : '#aaa'}
            />
          </Pressable>
        ))}
      {onMore && (
        <Pressable hitSlop={10} onPress={onMore} style={styles.iconButton}>
          <Ionicons name="ellipsis-vertical" size={18} color="#aaa" />
        </Pressable>
      )}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 8,
    paddingHorizontal: 16,
  },
  artwork: {
    width: 48,
    height: 48,
    borderRadius: 4,
    backgroundColor: '#222',
  },
  info: {
    flex: 1,
    marginLeft: 12,
  },
  title: {
    color: '#fff',
    fontSize: 15,
    fontWeight: '600',
  },
  activeText: {
    color: '#1DB954',
  },
  artist: {
    color: '#9b9b9b',
    fontSize: 13,
    marginTop: 2,
  },
  iconButton: {
    paddingHorizontal: 6,
    justifyContent: 'center',
    alignItems: 'center',
  },
});
