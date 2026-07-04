import React, { useLayoutEffect } from 'react';
import { View, Text, FlatList, StyleSheet, Pressable, Alert, SafeAreaView } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useLibrary } from '../contexts/LibraryContext';
import { usePlayer } from '../contexts/PlayerContext';
import TrackRow from '../components/TrackRow';

export default function PlaylistDetailScreen({ route, navigation }: any) {
  const { playlistId } = route.params;
  const { playlists, removeFromPlaylist, deletePlaylist, isFavorite, toggleFavorite, isDownloaded, downloadTrack, downloadingIds } =
    useLibrary();
  const { playQueue, currentTrack } = usePlayer();

  const playlist = playlists.find((p) => p.id === playlistId);

  useLayoutEffect(() => {
    navigation.setOptions({
      title: playlist?.name ?? 'Playlist',
      headerStyle: { backgroundColor: '#121212' },
      headerTintColor: '#fff',
      headerRight: () => (
        <Pressable
          hitSlop={10}
          onPress={() => {
            Alert.alert('Excluir playlist', `Excluir "${playlist?.name}"?`, [
              { text: 'Cancelar', style: 'cancel' },
              {
                text: 'Excluir',
                style: 'destructive',
                onPress: () => {
                  deletePlaylist(playlistId);
                  navigation.goBack();
                },
              },
            ]);
          }}
        >
          <Ionicons name="trash-outline" size={22} color="#ff6b6b" />
        </Pressable>
      ),
    });
  }, [navigation, playlist, playlistId, deletePlaylist]);

  if (!playlist) {
    return (
      <SafeAreaView style={styles.container}>
        <Text style={styles.empty}>Playlist não encontrada.</Text>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <FlatList
        data={playlist.tracks}
        keyExtractor={(item) => item.id}
        ListHeaderComponent={<Text style={styles.count}>{playlist.tracks.length} músicas</Text>}
        ListEmptyComponent={<Text style={styles.empty}>Adicione músicas a esta playlist pelo botão "⋮".</Text>}
        renderItem={({ item }) => (
          <TrackRow
            track={item}
            isActive={currentTrack?.id === item.id}
            isFavorite={isFavorite(item.id)}
            isDownloaded={isDownloaded(item.id)}
            downloadProgress={downloadingIds[item.id]}
            onPress={() => playQueue(playlist.tracks, playlist.tracks.findIndex((t) => t.id === item.id))}
            onToggleFavorite={() => toggleFavorite(item)}
            onDownload={() => downloadTrack(item)}
            onMore={() => removeFromPlaylist(playlist.id, item.id)}
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
  count: {
    color: '#9b9b9b',
    paddingHorizontal: 16,
    paddingVertical: 12,
  },
  empty: {
    color: '#9b9b9b',
    padding: 16,
    textAlign: 'center',
  },
});
