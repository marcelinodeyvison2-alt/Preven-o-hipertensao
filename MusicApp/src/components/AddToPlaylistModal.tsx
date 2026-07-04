import React from 'react';
import { Modal, View, Text, Pressable, StyleSheet, FlatList } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useLibrary } from '../contexts/LibraryContext';
import { Track } from '../types';

interface AddToPlaylistModalProps {
  visible: boolean;
  track: Track | null;
  onClose: () => void;
}

export default function AddToPlaylistModal({ visible, track, onClose }: AddToPlaylistModalProps) {
  const { playlists, addToPlaylist, createPlaylist } = useLibrary();

  if (!track) return null;

  return (
    <Modal visible={visible} transparent animationType="slide" onRequestClose={onClose}>
      <Pressable style={styles.overlay} onPress={onClose}>
        <Pressable style={styles.sheet} onPress={(e) => e.stopPropagation()}>
          <Text style={styles.title}>Adicionar a playlist</Text>
          <Text style={styles.subtitle} numberOfLines={1}>
            {track.title} · {track.artist}
          </Text>

          <FlatList
            data={playlists}
            keyExtractor={(item) => item.id}
            style={{ maxHeight: 300, marginTop: 12 }}
            ListEmptyComponent={<Text style={styles.empty}>Você ainda não tem playlists.</Text>}
            renderItem={({ item }) => {
              const alreadyIn = item.tracks.some((t) => t.id === track.id);
              return (
                <Pressable
                  style={styles.row}
                  onPress={() => {
                    if (!alreadyIn) addToPlaylist(item.id, track);
                    onClose();
                  }}
                >
                  <Ionicons name="musical-notes-outline" size={20} color="#1DB954" />
                  <Text style={styles.rowText}>{item.name}</Text>
                  {alreadyIn && <Ionicons name="checkmark" size={18} color="#1DB954" />}
                </Pressable>
              );
            }}
          />

          <Pressable
            style={styles.newPlaylistButton}
            onPress={() => {
              const playlist = createPlaylist(`Playlist ${new Date().toLocaleDateString('pt-BR')}`);
              addToPlaylist(playlist.id, track);
              onClose();
            }}
          >
            <Ionicons name="add" size={20} color="#000" />
            <Text style={styles.newPlaylistText}>Nova playlist</Text>
          </Pressable>
        </Pressable>
      </Pressable>
    </Modal>
  );
}

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.6)',
    justifyContent: 'flex-end',
  },
  sheet: {
    backgroundColor: '#282828',
    borderTopLeftRadius: 16,
    borderTopRightRadius: 16,
    padding: 20,
    paddingBottom: 32,
  },
  title: {
    color: '#fff',
    fontSize: 18,
    fontWeight: '700',
  },
  subtitle: {
    color: '#9b9b9b',
    marginTop: 4,
  },
  empty: {
    color: '#9b9b9b',
    paddingVertical: 12,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    paddingVertical: 12,
  },
  rowText: {
    color: '#fff',
    fontSize: 15,
    flex: 1,
  },
  newPlaylistButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    backgroundColor: '#1DB954',
    borderRadius: 24,
    paddingVertical: 12,
    marginTop: 16,
  },
  newPlaylistText: {
    color: '#000',
    fontWeight: '700',
  },
});
