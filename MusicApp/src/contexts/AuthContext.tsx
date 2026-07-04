import React, { createContext, useContext, useEffect, useMemo, useState } from 'react';
import {
  createUserWithEmailAndPassword,
  onAuthStateChanged,
  signInWithCredential,
  signInWithEmailAndPassword,
  signOut as firebaseSignOut,
  updateProfile,
  GoogleAuthProvider,
  User,
} from 'firebase/auth';
import * as Google from 'expo-auth-session/providers/google';
import * as WebBrowser from 'expo-web-browser';
import { auth, googleAuthConfig } from '../config/firebase';

WebBrowser.maybeCompleteAuthSession();

interface AuthContextValue {
  user: User | null;
  initializing: boolean;
  signIn: (email: string, password: string) => Promise<void>;
  signUp: (name: string, email: string, password: string) => Promise<void>;
  signOutUser: () => Promise<void>;
  signInWithGoogle: () => Promise<void>;
  googleReady: boolean;
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [initializing, setInitializing] = useState(true);

  const hasGoogleConfig = Boolean(
    googleAuthConfig.expoClientId || googleAuthConfig.androidClientId || googleAuthConfig.webClientId
  );

  const [request, response, promptAsync] = Google.useAuthRequest({
    clientId: googleAuthConfig.expoClientId || googleAuthConfig.webClientId,
    androidClientId: googleAuthConfig.androidClientId,
    webClientId: googleAuthConfig.webClientId,
  });

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, (firebaseUser) => {
      setUser(firebaseUser);
      setInitializing(false);
    });
    return unsubscribe;
  }, []);

  useEffect(() => {
    if (response?.type === 'success' && response.params?.id_token) {
      const credential = GoogleAuthProvider.credential(response.params.id_token);
      signInWithCredential(auth, credential).catch((err) => {
        console.warn('Falha no login com Google', err);
      });
    }
  }, [response]);

  const value = useMemo<AuthContextValue>(
    () => ({
      user,
      initializing,
      signIn: async (email, password) => {
        await signInWithEmailAndPassword(auth, email.trim(), password);
      },
      signUp: async (name, email, password) => {
        const credential = await createUserWithEmailAndPassword(auth, email.trim(), password);
        if (name.trim()) {
          await updateProfile(credential.user, { displayName: name.trim() });
        }
      },
      signOutUser: async () => {
        await firebaseSignOut(auth);
      },
      signInWithGoogle: async () => {
        if (!hasGoogleConfig) {
          throw new Error(
            'Login com Google não configurado. Preencha as chaves EXPO_PUBLIC_GOOGLE_* no arquivo .env.'
          );
        }
        await promptAsync();
      },
      googleReady: hasGoogleConfig && !!request,
    }),
    [user, initializing, request, hasGoogleConfig]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth deve ser usado dentro de AuthProvider');
  return ctx;
}

export function authErrorMessage(error: unknown): string {
  const code = (error as { code?: string })?.code ?? '';
  switch (code) {
    case 'auth/invalid-email':
      return 'E-mail inválido.';
    case 'auth/user-not-found':
    case 'auth/wrong-password':
    case 'auth/invalid-credential':
      return 'E-mail ou senha incorretos.';
    case 'auth/email-already-in-use':
      return 'Já existe uma conta com esse e-mail.';
    case 'auth/weak-password':
      return 'A senha precisa ter pelo menos 6 caracteres.';
    default:
      return (error as Error)?.message || 'Ocorreu um erro. Tente novamente.';
  }
}
