import React, { useState } from 'react';
import { View, Text, ScrollView, Pressable, StyleSheet, Modal, TextInput, SafeAreaView } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useLibrary } from '../contexts/LibraryContext';
import { usePlayer } from '../contexts/PlayerContext';
import TrackRow from '../components/TrackRow';

export default function LibraryScreen({ navigation }: any) {
  const { favorites, playlists, createPlaylist, isDownloaded, downloadTrack, downloadingIds, toggleFavorite } =
    useLibrary();
  const { playQueue, currentTrack } = usePlayer();
  const [modalVisible, setModalVisible] = useState(false);
  const [newName, setNewName] = useState('');

  function handleCreate() {
    if (!newName.trim()) return;
    const playlist = createPlaylist(newName);
    setNewName('');
    setModalVisible(false);
    navigation.navigate('PlaylistDetail', { playlistId: playlist.id });
  }

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView contentContainerStyle={{ paddingBottom: 140 }}>
        <View style={styles.headerRow}>
          <Text style={styles.header}>Sua Biblioteca</Text>
          <Pressable onPress={() => setModalVisible(true)} hitSlop={10}>
            <Ionicons name="add-circle-outline" size={28} color="#fff" />
          </Pressable>
        </View>

        <Text style={styles.sectionTitle}>Músicas curtidas ({favorites.length})</Text>
        {favorites.length === 0 ? (
          <Text style={styles.empty}>Toque no coração de uma música para curtir.</Text>
        ) : (
          favorites.map((track) => (
            <TrackRow
              key={track.id}
              track={track}
              isActive={currentTrack?.id === track.id}
              isFavorite
              isDownloaded={isDownloaded(track.id)}
              downloadProgress={downloadingIds[track.id]}
              onPress={() => playQueue(favorites, favorites.findIndex((t) => t.id === track.id))}
              onToggleFavorite={() => toggleFavorite(track)}
              onDownload={() => downloadTrack(track)}
            />
          ))
        )}

        <Text style={styles.sectionTitle}>Playlists</Text>
        {playlists.length === 0 ? (
          <Text style={styles.empty}>Crie sua primeira playlist com o botão +.</Text>
        ) : (
          playlists.map((playlist) => (
            <Pressable
              key={playlist.id}
              style={styles.playlistRow}
              onPress={() => navigation.navigate('PlaylistDetail', { playlistId: playlist.id })}
            >
              <View style={styles.playlistIcon}>
                <Ionicons name="musical-notes" size={22} color="#1DB954" />
              </View>
              <View style={{ flex: 1 }}>
                <Text style={styles.playlistName}>{playlist.name}</Text>
                <Text style={styles.playlistCount}>{playlist.tracks.length} músicas</Text>
              </View>
              <Ionicons name="chevron-forward" size={18} color="#666" />
            </Pressable>
          ))
        )}
      </ScrollView>

      <Modal visible={modalVisible} transparent animationType="fade" onRequestClose={() => setModalVisible(false)}>
        <View style={styles.modalOverlay}>
          <View style={styles.modalCard}>
            <Text style={styles.modalTitle}>Nova playlist</Text>
            <TextInput
              style={styles.modalInput}
              placeholder="Nome da playlist"
              placeholderTextColor="#888"
              value={newName}
              onChangeText={setNewName}
              autoFocus
            />
            <View style={styles.modalActions}>
              <Pressable onPress={() => setModalVisible(false)} style={styles.modalButton}>
                <Text style={styles.modalButtonText}>Cancelar</Text>
              </Pressable>
              <Pressable onPress={handleCreate} style={[styles.modalButton, styles.modalButtonPrimary]}>
                <Text style={[styles.modalButtonText, styles.modalButtonTextPrimary]}>Criar</Text>
              </Pressable>
            </View>
          </View>
        </View>
      </Modal>
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
  sectionTitle: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '700',
    marginTop: 24,
    marginBottom: 8,
    paddingHorizontal: 16,
  },
  empty: {
    color: '#9b9b9b',
    paddingHorizontal: 16,
  },
  playlistRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 10,
  },
  playlistIcon: {
    width: 48,
    height: 48,
    borderRadius: 4,
    backgroundColor: '#222',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  playlistName: {
    color: '#fff',
    fontSize: 15,
    fontWeight: '600',
  },
  playlistCount: {
    color: '#9b9b9b',
    fontSize: 13,
    marginTop: 2,
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.6)',
    justifyContent: 'center',
    paddingHorizontal: 32,
  },
  modalCard: {
    backgroundColor: '#282828',
    borderRadius: 12,
    padding: 20,
  },
  modalTitle: {
    color: '#fff',
    fontSize: 18,
    fontWeight: '700',
    marginBottom: 16,
  },
  modalInput: {
    backgroundColor: '#3a3a3a',
    color: '#fff',
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 10,
  },
  modalActions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    marginTop: 16,
    gap: 16,
  },
  modalButton: {
    paddingVertical: 8,
    paddingHorizontal: 12,
  },
  modalButtonPrimary: {
    backgroundColor: '#1DB954',
    borderRadius: 20,
  },
  modalButtonText: {
    color: '#ccc',
    fontWeight: '600',
  },
  modalButtonTextPrimary: {
    color: '#000',
  },
});
