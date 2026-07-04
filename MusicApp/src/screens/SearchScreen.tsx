import React, { useEffect, useRef, useState } from 'react';
import { View, Text, TextInput, FlatList, StyleSheet, ActivityIndicator, SafeAreaView } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { searchTracks } from '../services/jamendoApi';
import TrackRow from '../components/TrackRow';
import AddToPlaylistModal from '../components/AddToPlaylistModal';
import { usePlayer } from '../contexts/PlayerContext';
import { useLibrary } from '../contexts/LibraryContext';
import { Track } from '../types';

export default function SearchScreen() {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<Track[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [trackForPlaylist, setTrackForPlaylist] = useState<Track | null>(null);
  const debounceRef = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);

  const { playQueue, currentTrack } = usePlayer();
  const { isFavorite, toggleFavorite, isDownloaded, downloadTrack, downloadingIds } = useLibrary();

  useEffect(() => {
    if (debounceRef.current) clearTimeout(debounceRef.current);
    if (!query.trim()) {
      setResults([]);
      setError('');
      return;
    }
    debounceRef.current = setTimeout(async () => {
      setLoading(true);
      setError('');
      try {
        const tracks = await searchTracks(query.trim());
        setResults(tracks);
      } catch (err: any) {
        setError(err?.message ?? 'Falha na busca.');
      } finally {
        setLoading(false);
      }
    }, 500);
    return () => {
      if (debounceRef.current) clearTimeout(debounceRef.current);
    };
  }, [query]);

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.searchBox}>
        <Ionicons name="search" size={18} color="#888" style={{ marginRight: 8 }} />
        <TextInput
          style={styles.input}
          placeholder="O que você quer ouvir?"
          placeholderTextColor="#888"
          value={query}
          onChangeText={setQuery}
          autoCapitalize="none"
        />
      </View>

      {loading && <ActivityIndicator color="#1DB954" style={{ marginTop: 16 }} />}
      {!!error && <Text style={styles.error}>{error}</Text>}

      <FlatList
        data={results}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => (
          <TrackRow
            track={item}
            isActive={currentTrack?.id === item.id}
            isFavorite={isFavorite(item.id)}
            isDownloaded={isDownloaded(item.id)}
            downloadProgress={downloadingIds[item.id]}
            onPress={() => playQueue(results, results.findIndex((t) => t.id === item.id))}
            onToggleFavorite={() => toggleFavorite(item)}
            onDownload={() => downloadTrack(item)}
            onMore={() => setTrackForPlaylist(item)}
          />
        )}
        ListEmptyComponent={
          !loading && query.trim() ? <Text style={styles.empty}>Nenhum resultado encontrado.</Text> : null
        }
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
  searchBox: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#222',
    borderRadius: 8,
    marginHorizontal: 16,
    marginTop: 12,
    marginBottom: 8,
    paddingHorizontal: 12,
  },
  input: {
    flex: 1,
    color: '#fff',
    paddingVertical: 10,
    fontSize: 15,
  },
  error: {
    color: '#ff6b6b',
    paddingHorizontal: 16,
    marginTop: 12,
  },
  empty: {
    color: '#9b9b9b',
    textAlign: 'center',
    marginTop: 32,
  },
});
