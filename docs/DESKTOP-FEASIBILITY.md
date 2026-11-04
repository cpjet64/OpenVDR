# Desktop streaming feasibility at the ALVR baseline

Investigation basis: OpenVDR commit `2caae684`, containing the pinned ALVR
v20.14.1 baseline. This is a source assessment, not an implemented or tested
stream. Quest hardware is unavailable. Baseline reproduction and dependency
inventory remain prerequisites to media-path changes.

## Recommendation

Prototype a distinct desktop mode on ALVR's existing connection and client
core, with a native Windows capture/encoder producer and a native OpenXR 2D
presentation path. Keep the PCVR path intact. `alvr/server_core` exposes an
encoded-video submission seam without requiring the OpenVR driver entry point;
it does **not** already provide a desktop capture-to-headset feature. This is
the shortest source-supported candidate, not a proven working integration.
The investigation found no evidence sufficient to justify replacing ALVR or
combining it with another complete streaming stack.

Target the first proof at one selected Windows display, SDR, one negotiated
codec and an explicitly controlled client. Start view-only; add audio and
remote input as separately verified capabilities. Desktop mode needs an
explicit negotiated mode and frame dimensions so a PCVR client cannot mistake
a flat frame for stereo video. Compatibility and fallback must be deliberate.

## Concrete seams and work

1. **Host lifecycle and negotiation.** `alvr/server_core/src/lib.rs` defines
   `ServerCoreContext::new`, `start_connection`, and `ServerCoreEvent` including
   connect, disconnect and `RequestIDR`. `alvr/server_core/src/c_api.rs` exposes
   corresponding initialization, event polling and video functions. A desktop
   host must own the core lifecycle, respond to these events and integrate its
   settings/session storage. `alvr/server_openvr/src/lib.rs` currently supplies
   the SteamVR entry point and calls the core; it is not a standalone desktop
   host. `alvr/server_core/src/connection.rs` negotiates per-eye resolution,
   refresh rate, codec and VR-oriented settings. Define and negotiate a desktop
   mode, aspect ratio, coded dimensions and capabilities end-to-end rather than
   assuming this handshake already represents a monitor.
2. **Capture and encoding.** On Windows, DXGI Desktop Duplication supplies a
   GPU surface per output and pointer metadata. Acquire/release frames correctly,
   handle timeout, access loss, display changes, rotation, pointer composition,
   protected content, adapter selection and bounded frame queues. It does not
   create a virtual display. [Microsoft's API documentation](https://learn.microsoft.com/en-us/windows/desktop/direct3ddxgi/desktop-dup-api)
   describes the surface and recovery behavior. Encode the selected surface in a
   supported low-latency format, with explicit conversion, dimensions, timestamps,
   codec configuration and keyframe control. The existing Windows encoder code
   is a useful starting point, not a drop-in library: `alvr/server_openvr/cpp/platform/win32/CEncoder.cpp`
   constructs `FrameRender`, receives OpenVR textures, poses and bounds, and
   forwards its texture to `VideoEncoder::Transmit`. The AMF and NVENC backends
   are in the same directory; software encoding is conditional on `ALVR_GPL`.
   Assess dependencies, GPU compatibility and licensing before reuse. A focused
   standalone encoder adapter may be smaller than extracting all of that pipeline.
3. **Encoded video transport.** `ServerCoreContext::set_video_config_nals` and
   `send_video_nal` in `alvr/server_core/src/lib.rs` accept codec configuration,
   encoded bytes, timestamp and IDR status; C equivalents are in
   `alvr/server_core/src/c_api.rs`. `alvr/server_core/src/connection.rs` queues
   and sends video over the existing stream. A producer must service `RequestIDR`,
   provide configuration and a decodable IDR on connect/reconnect and after loss,
   and use a coherent timestamp domain. Queue overflow marks the stream corrupt
   and requests another IDR. Validate codec framing and configuration against
   the actual client decoder; function names alone do not prove interchangeability.
   Existing VR-oriented statistics, bitrate feedback and tracking assumptions
   need review when frames originate from capture rather than a predicted VR pose.
4. **Headset presentation.** `alvr/client_core/src/connection.rs` receives video,
   requests IDRs on loss, and forwards encoded frames through the decoder callback.
   `alvr/client_openxr/src/stream.rs` initializes the decoder, obtains decoded
   frames, renders into two eye swapchains and builds a projection layer;
   `alvr/client_openxr/src/lib.rs` submits that layer. Android MediaCodec handling
   is in `alvr/client_core/src/video_decoder/android.rs`. Add a mode-specific
   path that copies the decoded image into a suitably sized OpenXR swapchain and
   submits a positioned, aspect-correct quad; do not reinterpret the stereo
   reprojection renderer as a desktop screen. OpenXR defines a quad for 2D content
   in a reference space ([Khronos reference](https://registry.khronos.org/OpenXR/specs/1.1/man/html/XrCompositionLayerQuad.html)).
   Validate decoder image lifetime, GPU interop, color range, resolution limits,
   frame timing and runtime behavior on real target hardware. Decide screen
   placement, recentering and fallback if the runtime cannot support the path.
5. **Audio.** `alvr/server_core/src/connection.rs` already creates a game-audio
   stream and invokes `alvr_audio::record_audio_blocking` on non-Linux hosts;
   `alvr/client_core/src/connection.rs` receives and plays it. Windows device
   handling also contains OpenVR property updates. Verify actual Windows loopback,
   selected/default device changes, channel layout, latency and reconnect without
   the driver; suppress or isolate VR-only property effects. Do not assume this
   establishes macOS system-audio capture. Microphone return is a separate choice.
6. **Input.** Existing `ServerCoreEvent::Buttons` and tracking are VR controller
   data, not an established desktop keyboard/mouse protocol. Define an explicit
   opt-in input capability and message semantics, client ray-to-quad coordinate
   mapping, keyboard/text path and Windows injection adapter. Handle focus, display
   geometry, key-up on disconnect, permissions, capture visibility and a reliable
   local way to disable control. Treat input authorization and transport security
   as product/security decisions; existing client trust must not be assumed to
   provide authenticated or encrypted remote control.
7. **Discovery and recovery.** `alvr/server_core/src/connection.rs` alternates
   manual client IPs and local discovery, records discovered clients and checks
   trust; optional auto-trust exists. `alvr/client_core/src/connection.rs` handles
   announcement, stream lifecycle, decoder loss and `StreamingStopped`. Reuse
   only after verifying user-facing pairing, trust persistence, manual addressing,
   reconnection and protocol security. Confirm address direction in the actual UI:
   the server's manual list is for client IPs. A fresh desktop stream must reset
   capture, decoder configuration, IDR, audio and held input state after reconnect.

## macOS feasibility

ScreenCaptureKit can provide display/window video and audio sample buffers with
user screen-recording permission; Apple's [framework documentation](https://developer.apple.com/documentation/screencapturekit)
and [macOS sample](https://developer.apple.com/documentation/screencapturekit/capturing-screen-content-in-macos)
describe capture and consent. A native adapter, hardware encoding, buffer/codec
conversion, permission UX and input authorization are still required. The sample's
macOS 15 requirement is specific to that sample, not a chosen product minimum.
ALVR's Windows encoder is not portable to macOS; compile and runtime support for
the server core and its dependencies on macOS are unproven. Verify audio capture
semantics, permission revocation, display changes and OS-version support on a
real Mac before committing to this route. Linux desktop is another qualification
track, not implied by either Windows or macOS feasibility.

## Staged evidence and decisions

1. Complete the baseline Windows reproduction and dependency inventory; inspect
   licenses and establish a reproducible native build before editing media paths.
2. Prove standalone capture and encoding on Windows with independent decode and
   image/color checks, including cursor and display-change recovery. Then prove
   negotiated desktop video through the real core and client, including loss,
   reconnect, IDR and bounded latency/queues. A local decoded frame is not an
   end-to-end headset result.
3. On actual supported headset hardware, exercise quad placement, readability,
   motion, sustained streaming and recovery without SteamVR. Test real system
   audio and opt-in input separately, including disconnect cleanup and security.
   Record host, headset, runtime, versions, codec and measured results.
4. Qualify macOS and Linux hosts independently, with real platform permissions,
   capture, audio, input and recovery; separately qualify Windows/Linux PCVR.
   No headset or end-to-end acceptance can be claimed until hardware is available.

Decisions for architecture review: desktop-mode protocol/version compatibility;
codec and encoder strategy across GPU vendors; screen placement and controls;
security model for discovery, trust and remote input; audio and microphone scope;
minimum macOS version; and whether virtual displays are a later requirement.
Performance, dependency and platform conclusions require measurement, not this
source inspection. No builds, capture, streaming or hardware tests were run.

## Architect decision — 2026-11-04

The linked architect session approved this sequence based on the assessment,
while explicitly reporting that its repository/source access failed. This was
an architecture decision, not independent source review or hardware acceptance.

- First prove real single-display SDR capture/encode and local decoding; then
  explicit desktop negotiation and a native opaque OpenXR quad. Qualify audio
  and input separately. Do not introduce a second complete streaming stack.
- Check protocol compatibility before deserializing changed packet layouts.
  Reuse an adequate existing check or add the smallest OpenVDR discriminator.
  Binary fields/enum changes are protocol changes, regardless of Serde defaults.
- Select desktop mode and acknowledge its configuration before delivering video.
  Unsupported mode must fail clearly; never silently fall back to PCVR or treat
  missing desktop geometry as stereo. Advertise audio/input unavailable initially.
- Negotiate mono presentation, coded dimensions and visible region, codec,
  defined 8-bit SDR color/range, frame rate and current session. Physical quad
  placement and size remain separate from image dimensions. Reject unsupported
  capture formats instead of mislabeling HDR as SDR.
- Reconnect for mode/codec/resolution changes initially. Flush old queues and
  decoder state, deliver codec initialization and an initial keyframe, and reject
  stale-session frames. Add session identity only if existing isolation is
  insufficient.
- Trace frame timestamps, matching, pacing and pose dependencies. Desktop frames
  must not require fabricated PCVR tracking; the quad uses local XR tracking.
- Validate supported/unsupported peers, retained PCVR selection, actual local
  decoded content, stale-frame rejection and bounded buffering. Quest runtime
  behavior remains pending hardware tests.

The next protocol review must include the actual handshake sequence, changed
packet definitions, and compatibility check relative to deserialization. No
desktop protocol or media implementation is included in the baseline checkpoint.
