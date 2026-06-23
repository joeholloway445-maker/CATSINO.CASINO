'use client'

import { useEffect, useRef } from 'react'
import * as THREE from 'three'
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js'
import type { Race, Frame, PhysicalMod } from '@/types/character'

interface Props {
  race: Race | null
  frame: Frame | null
  mod: PhysicalMod | null
}

const SILHOUETTE_COLOR = 0x2a2a3d

/**
 * Procedural placeholder humanoid. Stand-in for a real rigged glTF model —
 * the scene/camera/lighting/recolor/reshape pipeline here is what a future
 * licensed character asset would plug into; only this build() function
 * would change.
 */
function buildFigure(): THREE.Group {
  const group = new THREE.Group()
  const material = new THREE.MeshStandardMaterial({
    color: SILHOUETTE_COLOR,
    roughness: 0.5,
    metalness: 0.2,
    envMapIntensity: 1,
  })

  const torso = new THREE.Mesh(new THREE.CapsuleGeometry(0.32, 0.55, 8, 16), material)
  torso.position.y = 1.05
  torso.name = 'torso'
  torso.castShadow = true
  group.add(torso)

  const head = new THREE.Mesh(new THREE.SphereGeometry(0.22, 24, 24), material)
  head.position.y = 1.68
  head.name = 'head'
  head.castShadow = true
  group.add(head)

  const limbGeo = new THREE.CapsuleGeometry(0.09, 0.55, 8, 16)
  const positions: [string, number, number, number][] = [
    ['arm_l', -0.42, 1.1, 0],
    ['arm_r', 0.42, 1.1, 0],
    ['leg_l', -0.16, 0.4, 0],
    ['leg_r', 0.16, 0.4, 0],
  ]
  for (const [name, x, y, z] of positions) {
    const limb = new THREE.Mesh(limbGeo, material.clone())
    limb.position.set(x, y, z)
    limb.name = name
    limb.castShadow = true
    group.add(limb)
  }

  const accent = new THREE.Mesh(new THREE.TorusGeometry(0.24, 0.03, 8, 32), material.clone())
  accent.position.y = 1.05
  accent.rotation.x = Math.PI / 2
  accent.name = 'accent'
  accent.visible = false
  group.add(accent)

  return group
}

// Maps each race's texture.type (drawn from its AI-prompt visual brief) to
// material treatment, since the placeholder mesh has no real surface art.
const TEXTURE_MATERIAL: Record<string, Partial<THREE.MeshStandardMaterial>> = {
  radiant: { roughness: 0.25, metalness: 0.5 },
  mutated: { roughness: 0.85, metalness: 0.05 },
  abyssal: { roughness: 0.3, metalness: 0.6 },
  spectral: { roughness: 0.4, metalness: 0.1, transparent: true, opacity: 0.78 },
  phasic: { roughness: 0.35, metalness: 0.2, transparent: true, opacity: 0.7 },
  temporal: { roughness: 0.3, metalness: 0.7 },
  voidlike: { roughness: 0.6, metalness: 0.3 },
  symbiotic: { roughness: 0.8, metalness: 0.0 },
  digital: { roughness: 0.2, metalness: 0.4 },
  biotech: { roughness: 0.45, metalness: 0.55 },
  dimensional: { roughness: 0.3, metalness: 0.5 },
  amphibious: { roughness: 0.75, metalness: 0.05 },
  solar: { roughness: 0.2, metalness: 0.4 },
  crystalline: { roughness: 0.1, metalness: 0.7 },
  electric: { roughness: 0.25, metalness: 0.3 },
  morphic: { roughness: 0.4, metalness: 0.1 },
  regal: { roughness: 0.4, metalness: 0.6 },
  decayed: { roughness: 0.9, metalness: 0.0 },
  crystal: { roughness: 0.05, metalness: 0.8, transparent: true, opacity: 0.9 },
  celestial: { roughness: 0.2, metalness: 0.6 },
}

export default function CharacterPreview3DCanvas({ race, frame, mod }: Props) {
  const containerRef = useRef<HTMLDivElement>(null)
  const figureRef = useRef<THREE.Group | null>(null)

  useEffect(() => {
    const container = containerRef.current
    if (!container) return

    const scene = new THREE.Scene()
    scene.background = new THREE.Color(0x12121f)
    scene.fog = new THREE.Fog(0x12121f, 4, 9)

    const camera = new THREE.PerspectiveCamera(40, container.clientWidth / container.clientHeight, 0.1, 100)
    camera.position.set(0, 1.1, 3.2)

    const renderer = new THREE.WebGLRenderer({ antialias: true })
    renderer.setSize(container.clientWidth, container.clientHeight)
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2))
    renderer.shadowMap.enabled = true
    renderer.shadowMap.type = THREE.PCFSoftShadowMap
    container.appendChild(renderer.domElement)

    scene.add(new THREE.HemisphereLight(0x8aa2ff, 0x1a1a2a, 0.6))
    const key = new THREE.DirectionalLight(0xffffff, 1.4)
    key.position.set(2, 4, 3)
    key.castShadow = true
    key.shadow.mapSize.set(1024, 1024)
    scene.add(key)
    const rim = new THREE.DirectionalLight(0x6366f1, 0.8)
    rim.position.set(-3, 1.5, -2)
    scene.add(rim)
    const fill = new THREE.DirectionalLight(0xffffff, 0.3)
    fill.position.set(0, 1, -3)
    scene.add(fill)

    const ground = new THREE.Mesh(
      new THREE.CircleGeometry(1.6, 48),
      new THREE.MeshStandardMaterial({ color: 0x1c1c2e, roughness: 0.9, metalness: 0 })
    )
    ground.rotation.x = -Math.PI / 2
    ground.position.y = -0.9
    ground.receiveShadow = true
    scene.add(ground)

    const figure = buildFigure()
    figure.position.y = -0.9
    scene.add(figure)
    figureRef.current = figure

    const controls = new OrbitControls(camera, renderer.domElement)
    controls.target.set(0, 0.2, 0)
    controls.enablePan = false
    controls.minDistance = 2
    controls.maxDistance = 5
    controls.update()

    let frameId: number
    const animate = () => {
      figure.rotation.y += 0.004
      controls.update()
      renderer.render(scene, camera)
      frameId = requestAnimationFrame(animate)
    }
    animate()

    const onResize = () => {
      if (!container) return
      camera.aspect = container.clientWidth / container.clientHeight
      camera.updateProjectionMatrix()
      renderer.setSize(container.clientWidth, container.clientHeight)
    }
    window.addEventListener('resize', onResize)

    return () => {
      cancelAnimationFrame(frameId)
      window.removeEventListener('resize', onResize)
      controls.dispose()
      renderer.dispose()
      container.removeChild(renderer.domElement)
    }
  }, [])

  // Race -> base color (visuals)
  useEffect(() => {
    const figure = figureRef.current
    if (!figure) return
    const color = race ? race.texture.tintHex : SILHOUETTE_COLOR
    const treatment = race ? TEXTURE_MATERIAL[race.texture.type] : undefined
    figure.traverse((obj) => {
      if (obj instanceof THREE.Mesh && obj.material instanceof THREE.MeshStandardMaterial) {
        obj.material.color.setHex(color)
        obj.material.emissive.setHex(race ? color : 0x000000)
        obj.material.emissiveIntensity = race ? 0.18 : 0
        obj.material.roughness = treatment?.roughness ?? 0.5
        obj.material.metalness = treatment?.metalness ?? 0.2
        obj.material.transparent = treatment?.transparent ?? false
        obj.material.opacity = treatment?.opacity ?? 1
      }
    })
  }, [race])

  // Frame -> proportions (mobility/power read on the body)
  useEffect(() => {
    const figure = figureRef.current
    if (!figure || !frame) return
    const { agility, power } = frame.stats
    const lean = 0.85 + (agility / 10) * 0.3
    const bulk = 0.85 + (power / 10) * 0.3
    figure.scale.set(bulk, lean, bulk)
  }, [frame])

  // Mod -> visual flourish (the accent ring + limb thickness)
  useEffect(() => {
    const figure = figureRef.current
    if (!figure) return
    const accent = figure.getObjectByName('accent')
    if (accent) accent.visible = Boolean(mod)
    if (accent instanceof THREE.Mesh && mod && accent.material instanceof THREE.MeshStandardMaterial) {
      accent.material.color.setHex(race ? race.texture.tintHex : 0x9ca3af)
      accent.material.emissive.setHex(0xffffff)
      accent.material.emissiveIntensity = 0.4
    }
    const agilityMod = mod?.statModifier.agility ?? 0
    ;['leg_l', 'leg_r', 'arm_l', 'arm_r'].forEach((name) => {
      const limb = figure.getObjectByName(name)
      if (limb) limb.scale.set(1 + agilityMod * 0.08, 1, 1 + agilityMod * 0.08)
    })
  }, [mod, race])

  return <div ref={containerRef} className="w-full h-full" />
}
