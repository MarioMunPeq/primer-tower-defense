extends GPUParticles2D
## One-shot spark burst at projectile impact points and enemy deaths.
## Lifecycle is handled by the VfxSparkPool (recycle on a timer). This script is
## intentionally inert: relying on the GPUParticles2D `finished` signal for
## self-freeing is unreliable here, which caused leaking nodes.