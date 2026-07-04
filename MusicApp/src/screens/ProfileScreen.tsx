import React from 'react';
import { View, Text, StyleSheet, Pressable, SafeAreaView, Alert } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../contexts/AuthContext';
import { useLibrary } from '../contexts/LibraryContext';

export default function ProfileScreen() {
  const { user, signOutUser } = useAuth();
  const { favorites, playlists, downloads } = useLibrary();

  function handleLogout() {
    Alert.alert('Sair', 'Deseja sair da sua conta?', [
      { text: 'Cancelar', style: 'cancel' },
      { text: 'Sair', style: 'destructive', onPress: () => signOutUser() },
    ]);
  }

  const initial = (user?.displayName || user?.email || '?').charAt(0).toUpperCase();

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.avatar}>
        <Text style={styles.avatarText}>{initial}</Text>
      </View>
      <Text style={styles.name}>{user?.displayName || 'Usuário'}</Text>
      <Text style={styles.email}>{user?.email}</Text>

      <View style={styles.statsRow}>
        <View style={styles.statCard}>
          <Text style={styles.statNumber}>{favorites.length}</Text>
          <Text style={styles.statLabel}>Curtidas</Text>
        </View>
        <View style={styles.statCard}>
          <Text style={styles.statNumber}>{playlists.length}</Text>
          <Text style={styles.statLabel}>Playlists</Text>
        </View>
        <View style={styles.statCard}>
          <Text style={styles.statNumber}>{downloads.length}</Text>
          <Text style={styles.statLabel}>Baixadas</Text>
        </View>
      </View>

      <Pressable style={styles.logoutButton} onPress={handleLogout}>
        <Ionicons name="log-out-outline" size={20} color="#ff6b6b" />
        <Text style={styles.logoutText}>Sair da conta</Text>
      </Pressable>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#121212',
    alignItems: 'center',
    paddingTop: 48,
  },
  avatar: {
    width: 96,
    height: 96,
    borderRadius: 48,
    backgroundColor: '#1DB954',
    alignItems: 'center',
    justifyContent: 'center',
  },
  avatarText: {
    color: '#000',
    fontSize: 40,
    fontWeight: '800',
  },
  name: {
    color: '#fff',
    fontSize: 20,
    fontWeight: '700',
    marginTop: 16,
  },
  email: {
    color: '#9b9b9b',
    marginTop: 4,
  },
  statsRow: {
    flexDirection: 'row',
    marginTop: 32,
    gap: 12,
  },
  statCard: {
    backgroundColor: '#1e1e1e',
    borderRadius: 12,
    paddingVertical: 16,
    paddingHorizontal: 20,
    alignItems: 'center',
  },
  statNumber: {
    color: '#1DB954',
    fontSize: 20,
    fontWeight: '800',
  },
  statLabel: {
    color: '#9b9b9b',
    fontSize: 12,
    marginTop: 4,
  },
  logoutButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginTop: 48,
    paddingVertical: 12,
    paddingHorizontal: 24,
    borderRadius: 24,
    borderWidth: 1,
    borderColor: '#ff6b6b',
  },
  logoutText: {
    color: '#ff6b6b',
    fontWeight: '600',
  },
});
