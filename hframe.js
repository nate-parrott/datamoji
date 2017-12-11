
AFRAME.registerComponent('h-frame-scene', {
  init: function() {    
    this.el.setAttribute('vr-mode-ui', {enabled: false});
    this.el.setAttribute('embedded', true);
    
    let style = this.el.style;
    style.pointerEvents = 'none';
    style.height = '120vh';
    style.top = '-10vh';
    style.width = '100%';
    style.left = '0';
    style.position = 'absolute';
    
    this.camera = null;
    this.pixelToMeterScale = null; // multiply screen pixels by this to get aframe units (meters) for an object on the XZ plane
    this.pixelOriginOffset = null;
  
    
    this.el.sceneEl.addEventListener('camera-set-active', (e) => {      
      this.camera = e.detail.cameraEl;
      this.camera.setAttribute('position', {x: 0, y: 20, z: 0});
      this.camera.setAttribute('rotation', {x: -90, y: 0, z: 0});
      this.camera.setAttribute('wasd-controls', null);
      this.camera.setAttribute('look-controls', null);
      
      requestAnimationFrame(() => {
        this.resyncViewport(this.getCurrentViewport());
      });
    });
  },
  tick: function() {
    let viewport = this.getCurrentViewport();
    if (this.camera && !this.viewportsAreEqual(viewport, this.lastSyncedViewport)) {
      this.resyncViewport(viewport);
    }
  },
  getCurrentViewport: function() {
    return {x: window.scrollX, y: window.scrollY, width: window.innerWidth, height: window.innerHeight};
  },
  viewportsAreEqual: function(a, b) {
    if (!a || !b) return false;
    return a.x === b.x && a.y === b.y && a.width === b.width && a.height === b.height;
  },
  resyncViewport: function(viewport) {
    let sceneTop = (viewport.y - viewport.height * 0.1);
    this.el.style.top = sceneTop + 'px';
    this.el.style.height = '120vh'; // sceneHeight + 'px';
    
    let camera = this.camera.getObject3D('camera');
    let pos1 = this.convertClientPosToVec({x: 0, y: 0}, this.el, camera);
    let pos2 = this.convertClientPosToVec({x: 100, y: 100}, this.el, camera);
    this.pixelToMeterScale = (pos2.x - pos1.x) / 100;
    
    let sceneRect = this.el.getBoundingClientRect();
    this.pixelOriginOffset = {x: sceneRect.width / 2 - sceneRect.x, y: sceneRect.height / 2 + sceneTop};
    
    this.lastSyncedViewport = viewport;
  },
  convertClientPosToVec: function(pos, scene, camera) {
    let sceneSize = scene.getBoundingClientRect();
    let XZPlane = new THREE.Plane(new THREE.Vector3(0, 1, 0), 0);
    let screenPos = new THREE.Vector2((pos.x - sceneSize.x) / sceneSize.width * 2 - 1, -(pos.y - sceneSize.y) / sceneSize.height * 2 + 1);
    let raycaster = new THREE.Raycaster();
    raycaster.setFromCamera(screenPos, camera);    
    let intersection = raycaster.ray.intersectPlane(XZPlane);
    return intersection;
  }
});

AFRAME.registerComponent('h-frame', {
  schema: { 
    anchor: { type: 'selector' }, 
    orbit: { type: 'string', default: "" },
    "orbit-target": { type: 'selector' }
  },
  init: function() {
    if (this.data.orbit) {
      if (this.data.anchor) {
        let allowX = this.data.orbit.indexOf('X') != -1;
        let allowY = this.data.orbit.indexOf('Y') != -1;
        let target = this.data['orbit-target'] || this.el;
        this.impetus = new Impetus({
          source: this.data.anchor,
          update: (x, y) => {
            let zRot = x * (allowX ? 1 : 0);
            let xRot = y * (allowY ? 1 : 0);
            target.setAttribute('rotation', {x: xRot, y: 0, z: -zRot});
          }
        })
      } else {
        console.error("A component can't have h-frame.orbit set without an h-frame.anchor");
      }
    }
  },
  tick: function() {
    if (this.data.anchor) {
      this.updateAnchor(this.data.anchor);
    }
  },
  updateAnchor(anchor) {
    let scene = this.el.sceneEl;
    let hframe = scene.components['h-frame-scene'];
    let targetBox = anchor.getBoundingClientRect();
    targetBox.y += window.scrollY;
    targetBox.x += window.scrollX;

    if (hframe && hframe.pixelToMeterScale) {
      let centerPos;
      if (this.data === document.body) {
        centerPos = {x: targetBox.x + targetBox.width/2, y: targetBox.y};
      } else {
        centerPos = {x: targetBox.x + targetBox.width/2, y: targetBox.y + targetBox.height/2};
      }
      this.el.object3D.position.set((centerPos.x - hframe.pixelOriginOffset.x) * hframe.pixelToMeterScale, 0, (centerPos.y - hframe.pixelOriginOffset.y) * hframe.pixelToMeterScale);
      if (this.data !== document.body) {
        let scale = Math.min(targetBox.width, targetBox.height) * hframe.pixelToMeterScale;
        this.el.object3D.scale.set(scale, scale, scale);
      }
    }
  }
});

AFRAME.registerComponent('h-frame-shadow-catcher', {
  init: function() {
    this.el.setAttribute('geometry', {primitive: 'plane'});
    // this.el.setAttribute('width', 1000);
    // this.el.setAttribute('height', 1000);
    this.el.setAttribute('shadow', true);
    this.el.setAttribute('rotation', {x: -90, y: 0, z: 0});
    this.el.setAttribute('scale', {x: 100, y: 100, z: 100});
      let material = new THREE.ShadowMaterial();
      material.opacity = 0.25;
      this.el.getObject3D('mesh').material = material;
  }
});

