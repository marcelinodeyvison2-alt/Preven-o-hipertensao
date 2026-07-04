import React, { useEffect, useState, useCallback } from 'react';
import { View, Text, FlatList, StyleSheet, ActivityIndicator, ScrollView, Pressable, SafeAreaView } from 'react-native';
import { getPopularTracks, getTracksByTag, GENRES } from '../services/jamendoApi';
import TrackRow from '../components/TrackRow';
import AddToPlaylistModal from '../components/AddToPlaylistModal';
import { usePlayer } from '../contexts/PlayerContext';
import { useLibrary } from '../contexts/LibraryContext';
import { Track } from '../types';

export default function HomeScreen() {
  const [tracks, setTracks] = useState<Track[]>([]);
  const [genre, setGenre] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [trackForPlaylist, setTrackForPlaylist] = useState<Track | null>(null);
  const { playQueue, currentTrack } = usePlayer();
  const { isFavorite, toggleFavorite, isDownloaded, downloadTrack, downloadingIds } = useLibrary();

  const load = useCallback(async (selectedGenre: string | null) => {
    setLoading(true);
    setError('');
    try {
      const result = selectedGenre ? await getTracksByTag(selectedGenre) : await getPopularTracks();
      setTracks(result);
    } catch (err: any) {
      setError(err?.message ?? 'Não foi possível carregar as músicas.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load(genre);
  }, [genre, load]);

  return (
    <SafeAreaView style={styles.container}>
      <FlatList
        data={tracks}
        keyExtractor={(item) => item.id}
        ListHeaderComponent={
          <View>
            <Text style={styles.header}>Bom te ver de novo</Text>
            <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.chipsRow}>
              <Pressable style={[styles.chip, !genre && styles.chipActive]} onPress={() => setGenre(null)}>
                <Text style={[styles.chipText, !genre && styles.chipTextActive]}>Populares</Text>
              </Pressable>
              {GENRES.map((g) => (
                <Pressable
                  key={g}
                  style={[styles.chip, genre === g && styles.chipActive]}
                  onPress={() => setGenre(g)}
                >
                  <Text style={[styles.chipText, genre === g && styles.chipTextActive]}>{g}</Text>
                </Pressable>
              ))}
            </ScrollView>
            {loading && <ActivityIndicator color="#1DB954" style={{ marginTop: 20 }} />}
            {!!error && <Text style={styles.error}>{error}</Text>}
          </View>
        }
        renderItem={({ item }) => (
          <TrackRow
            track={item}
            isActive={currentTrack?.id === item.id}
            isFavorite={isFavorite(item.id)}
            isDownloaded={isDownloaded(item.id)}
            downloadProgress={downloadingIds[item.id]}
            onPress={() => playQueue(tracks, tracks.findIndex((t) => t.id === item.id))}
            onToggleFavorite={() => toggleFavorite(item)}
            onDownload={() => downloadTrack(item)}
            onMore={() => setTrackForPlaylist(item)}
          />
        )}
        contentContainerStyle={{ paddingBottom: 140 }}
      />
      <AddToPlaylistModal
        visible={!!trackForPlaylist}
        track={trackForPlaylist}
        onClose={() => setTrackForPlaylist(null)}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#121212',
  },
  header: {
    color: '#fff',
    fontSize: 22,
    fontWeight: '800',
    paddingHorizontal: 16,
    paddingTop: 12,
    marginBottom: 12,
  },
  chipsRow: {
    paddingHorizontal: 16,
    marginBottom: 8,
  },
  chip: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 16,
    backgroundColor: '#222',
    marginRight: 8,
  },
  chipActive: {
    backgroundColor: '#1DB954',
  },
  chipText: {
    color: '#ccc',
    fontSize: 13,
    textTransform: 'capitalize',
  },
  chipTextActive: {
    color: '#000',
    fontWeight: '700',
  },
  error: {
    color: '#ff6b6b',
    paddingHorizontal: 16,
    marginTop: 12,
  },
});
