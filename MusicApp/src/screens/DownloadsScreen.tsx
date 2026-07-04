import React from 'react';
import { View, Text, FlatList, StyleSheet, Pressable, SafeAreaView } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useLibrary } from '../contexts/LibraryContext';
import { usePlayer } from '../contexts/PlayerContext';
import TrackRow from '../components/TrackRow';

export default function DownloadsScreen() {
  const { downloads, isFavorite, toggleFavorite, removeDownload } = useLibrary();
  const { playQueue, currentTrack } = usePlayer();

  const tracks = downloads.map((d) => d.track);

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.headerRow}>
        <Text style={styles.header}>Baixadas</Text>
        <Ionicons name="cloud-offline-outline" size={22} color="#1DB954" />
      </View>
      <Text style={styles.subtitle}>Disponíveis para ouvir sem internet</Text>

      <FlatList
        data={tracks}
        keyExtractor={(item) => item.id}
        ListEmptyComponent={
          <Text style={styles.empty}>
            Nenhuma música baixada ainda. Toque no ícone de download em qualquer faixa para ouvir offline.
          </Text>
        }
        renderItem={({ item }) => (
          <TrackRow
            track={item}
            isActive={currentTrack?.id === item.id}
            isFavorite={isFavorite(item.id)}
            isDownloaded
            onPress={() => playQueue(tracks, tracks.findIndex((t) => t.id === item.id))}
            onToggleFavorite={() => toggleFavorite(item)}
            onDownload={() => removeDownload(item.id)}
          />
        )}
        contentContainerStyle={{ paddingBottom: 140 }}
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#121212',
  },
  headerRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingTop: 12,
  },
  header: {
    color: '#fff',
    fontSize: 22,
    fontWeight: '800',
  },
  subtitle: {
    color: '#9b9b9b',
    paddingHorizontal: 16,
    marginTop: 4,
    marginBottom: 12,
  },
  empty: {
    color: '#9b9b9b',
    paddingHorizontal: 16,
    marginTop: 24,
    lineHeight: 20,
  },
});
