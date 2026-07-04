# MusicApp

App de música (React Native + Expo) com login, streaming online e download para
ouvir offline — parecido em funcionalidade com o Spotify, mas usando um catálogo
de música **livre de direitos autorais** (Jamendo), já que não é possível
distribuir o catálogo do Spotify fora da plataforma deles.

## Funcionalidades

- Login e cadastro com e-mail/senha (Firebase Authentication) + login com Google
- Busca de músicas e navegação por gêneros (catálogo Jamendo)
- Player completo: play/pause, próxima/anterior, barra de progresso, shuffle, repeat
- Mini player persistente em todas as telas
- Curtir músicas, criar e gerenciar playlists
- Baixar músicas para ouvir **sem internet** e gerenciar os downloads
- Perfil do usuário com estatísticas e logout

## 1. Configurar as chaves (obrigatório antes de rodar)

Copie `.env.example` para `.env` e preencha:

```bash
cp .env.example .env
```

### Jamendo (catálogo de música gratuito)
1. Crie uma conta grátis em https://devportal.jamendo.com/
2. Copie o `client_id` do seu app e cole em `EXPO_PUBLIC_JAMENDO_CLIENT_ID`

### Firebase (login)
1. Crie um projeto em https://console.firebase.google.com/
2. Em **Authentication > Sign-in method**, ative "E-mail/senha" e "Google"
3. Em **Configurações do projeto > Geral**, adicione um app Web e copie os
   valores para as variáveis `EXPO_PUBLIC_FIREBASE_*`

### Login com Google (opcional)
1. No Firebase, em Authentication > Sign-in method > Google, pegue o Web Client ID
2. Crie também um OAuth Client ID do tipo "Android" no Google Cloud Console
   (mesmo projeto do Firebase), usando o `package name` `com.musicapp.mobile`
   e o SHA-1 do seu keystore de build
3. Preencha `EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID` e `EXPO_PUBLIC_GOOGLE_ANDROID_CLIENT_ID`

Se você não configurar o Google, o app funciona normalmente só com e-mail/senha
(o botão de login com Google simplesmente não aparece).

## 2. Rodar em desenvolvimento

```bash
npm install
npx expo start
```

Escaneie o QR code com o app **Expo Go** no seu celular Android (mesma rede Wi-Fi).

## 3. Gerar o APK para instalar no celular

O build de verdade (compilar o app nativo Android) é feito na nuvem pela Expo,
gratuitamente, sem precisar de Android Studio instalado.

```bash
npm install -g eas-cli
eas login          # crie uma conta grátis em expo.dev se ainda não tiver
eas build -p android --profile preview
```

Ao terminar (leva ~10-15 minutos), o terminal mostra um link para baixar o
`.apk` — baixe direto no celular e instale (pode ser preciso permitir
"instalar apps de fontes desconhecidas" nas configurações do Android).

## Estrutura do projeto

```
src/
  config/       Configuração do Firebase e Jamendo
  contexts/     Estado global: autenticação, player de áudio, biblioteca (favoritos/playlists/downloads)
  services/     Chamadas à API Jamendo, download de arquivos, AsyncStorage
  navigation/   Navegação (login/registro, abas principais, player em modal)
  screens/      Telas do app
  components/   Componentes reutilizáveis (linha de música, mini player, etc.)
```

## Observações importantes

- O catálogo de músicas vem da **Jamendo**, uma plataforma de música
  independente e livre de direitos autorais. Não é o catálogo do Spotify.
- Os downloads ficam salvos localmente no armazenamento do app; desinstalar o
  app apaga as músicas baixadas.
- Cada usuário logado tem suas próprias curtidas, playlists e downloads,
  guardados no próprio aparelho.
