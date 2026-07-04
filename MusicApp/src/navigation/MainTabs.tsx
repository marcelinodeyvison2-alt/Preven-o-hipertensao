import React from 'react';
import { View, StyleSheet } from 'react-native';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { Ionicons } from '@expo/vector-icons';
import HomeScreen from '../screens/HomeScreen';
import SearchScreen from '../screens/SearchScreen';
import LibraryScreen from '../screens/LibraryScreen';
import DownloadsScreen from '../screens/DownloadsScreen';
import ProfileScreen from '../screens/ProfileScreen';
import MiniPlayer from '../components/MiniPlayer';

export type MainTabParamList = {
  Home: undefined;
  Search: undefined;
  Library: undefined;
  Downloads: undefined;
  Profile: undefined;
};

const ICONS: Record<keyof MainTabParamList, keyof typeof Ionicons.glyphMap> = {
  Home: 'home',
  Search: 'search',
  Library: 'albums',
  Downloads: 'download',
  Profile: 'person',
};

const Tab = createBottomTabNavigator<MainTabParamList>();

export default function MainTabs() {
  return (
    <View style={styles.container}>
      <Tab.Navigator
        screenOptions={({ route }) => ({
          headerShown: false,
          tabBarActiveTintColor: '#1DB954',
          tabBarInactiveTintColor: '#888',
          tabBarStyle: styles.tabBar,
          tabBarIcon: ({ color, size }) => (
            <Ionicons name={ICONS[route.name as keyof MainTabParamList]} color={color} size={size} />
          ),
        })}
      >
        <Tab.Screen name="Home" component={HomeScreen} options={{ title: 'Início' }} />
        <Tab.Screen name="Search" component={SearchScreen} options={{ title: 'Buscar' }} />
        <Tab.Screen name="Library" component={LibraryScreen} options={{ title: 'Biblioteca' }} />
        <Tab.Screen name="Downloads" component={DownloadsScreen} options={{ title: 'Baixadas' }} />
        <Tab.Screen name="Profile" component={ProfileScreen} options={{ title: 'Perfil' }} />
      </Tab.Navigator>
      <MiniPlayer />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#121212',
  },
  tabBar: {
    backgroundColor: '#000000',
    borderTopColor: '#222',
    height: 58,
    paddingBottom: 6,
    paddingTop: 6,
  },
});
