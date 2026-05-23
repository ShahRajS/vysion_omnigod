# Gemini Live Integration — Execution Plan

## Reference Sources
- **Working protocol**: `~/gdg-hackathon/test_live_api.py` (v1beta, setupComplete handshake, clientContent turns)
- **Blueprint**: `systemDesign/vysion_blueprint.md` (Phases 6, 9, 11)
- **Current stub**: `lib/core/ai/gemini_live_client.dart` (needs rewrite)
- **Consumer**: `lib/features/capture/ui/capture_page.dart` (needs wiring)

---

## Phase 1: Fix GeminiLiveClient Protocol (gemini_live_client.dart)
- [ ] Change WebSocket endpoint from `v1alpha` to `v1beta` to match working Python test
- [ ] Add API key connection mode (direct `?key=` param for hackathon dev, keep OAuth path for prod)
- [ ] Update model to `models/gemini-2.5-flash-preview` (blueprint target) with fallback constant
- [ ] Implement `setupComplete` handshake — wait for server confirmation before allowing sends
- [ ] Add `clientContent` message type for text-based queries (Navigate mode voice commands)
- [ ] Parse `turnComplete` from `serverContent` to know when model is done responding
- [ ] Register `getRoute` tool in setup message per blueprint Phase 11 tool registry
- [ ] Handle `toolCall` responses from server (emit on a dedicated stream for the navigation layer)
- [ ] Add connection state enum: `disconnected`, `connecting`, `setupPending`, `ready`, `error`
- [ ] Add auto-reconnect with exponential backoff (cap at 30s, max 5 retries)
- [ ] Add `dispose()` that closes streams and channel cleanly
- Verify: Connect to Gemini Live, get `setupComplete`, send a text query, receive streamed response with `turnComplete`

## Phase 2: Camera Frame Streaming Pipeline
- [ ] Create `lib/core/ai/frame_streamer.dart` — manages camera → WebSocket frame pacing
- [ ] Implement frame capture from `CameraController.startImageStream()` with JPEG encoding
- [ ] Set target frame rate: 1 FPS for Describe mode (bandwidth-efficient), configurable
- [ ] Apply JPEG quality compression (quality: 50-70) to keep frames under ~50KB
- [ ] Add backpressure: skip frames if WebSocket send buffer exceeds threshold
- [ ] Wire frame streamer to `GeminiLiveClient.sendVideoFrame()` 
- [ ] Add start/stop controls tied to CaptureMode (only stream in Describe and Navigate modes)
- Verify: Camera frames are captured, JPEG-encoded, base64'd, and sent as `realtimeInput.mediaChunks` at ~1 FPS

## Phase 3: Audio Response Playback
- [ ] Create `lib/core/ai/audio_player_service.dart` — plays PCM audio chunks from Gemini
- [ ] Buffer incoming PCM audio chunks (24kHz, 16-bit) from `GeminiLiveClient.audioStream`
- [ ] Use platform audio output (investigate `just_audio` raw PCM or platform channels)
- [ ] Handle audio queue: buffer chunks, play sequentially, clear on mode switch or cancel
- [ ] Integrate with TTS fallback: if audio stream is empty/errored, fall back to local TTS
- Verify: Gemini audio responses play through device speaker/headset in real-time

## Phase 4: Wire CapturePage to Live Pipeline
- [ ] Replace mock `_performLiveDescribe()` with real Gemini Live connection + frame streaming
- [ ] On Describe mode tap: connect to Gemini (if not connected), start frame streamer, listen to text/audio streams
- [ ] On Navigate mode tap: connect to Gemini, send `clientContent` voice query, handle `toolCall` for `getRoute`
- [ ] Display connection state in UI header (replace hardcoded "LIVE" indicator)
- [ ] Wire double-tap cancel to stop frame streaming + disconnect
- [ ] Wire mode switch to pause/resume frame streaming appropriately
- [ ] Handle `textStream` — speak via TTS as fallback, display in accessibility overlay
- [ ] Handle `audioStream` — route to AudioPlayerService for direct playback
- Verify: Full loop works — tap Describe, camera streams to Gemini, audio description plays back

## Phase 5: Dev-Mode API Key Support (Hackathon Fast Path)
- [ ] Add `GEMINI_API_KEY` to `AppConfig` as optional compile-time var
- [ ] When `GEMINI_API_KEY` is set, connect directly with `?key=` (skip backend token flow)
- [ ] When not set, use existing backend `/v1/gemini/token` ephemeral token flow
- [ ] Add connection mode indicator in settings or debug overlay
- Verify: App connects to Gemini Live using direct API key without needing backend running

## Phase 6: Verification & Edge Cases
- [ ] Test with no network — graceful degradation to offline OCR mode
- [ ] Test reconnection — kill WebSocket mid-stream, verify auto-reconnect and frame resume
- [ ] Test mode switching — Describe → Read → Describe doesn't leak connections
- [ ] Test audio interruption — double-tap cancel stops audio playback immediately
- [ ] Verify VoiceOver compatibility — connection state changes are announced
- [ ] Memory: ensure frame streamer stops when app goes to background (WidgetsBindingObserver)
- Verify: No resource leaks, graceful error handling, accessible state announcements
