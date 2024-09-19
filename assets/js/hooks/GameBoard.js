import * as PIXI from 'pixi.js';

let GameBoard = {
  gradientCircleSprite({ centerX, centerY, radius, steps, color, dividingFactor }) {
    // Create a new Graphics object
    const graphics = new PIXI.Graphics();

    // Draw the radial gradient
    for (let i = steps; i > 0; i--) {
      const stepRadius = radius * (i / steps);
      const alpha = Math.min(
        ((i / steps) ** -5) / dividingFactor,
        0.01
      );

      // graphics.beginFill(0xFFFFFF, alpha); // White with varying alpha
      graphics.beginFill(color, alpha); // White with varying alpha
      graphics.drawCircle(centerX, centerY, stepRadius);
      graphics.endFill();
    }

    // Generate a texture from the graphics object
    const texture = this.app.renderer.generateTexture(graphics);

    // Create a sprite using the generated texture
    const sprite = new PIXI.Sprite(texture);

    // Position the sprite
    sprite.x = centerX - radius;
    sprite.y = centerY - radius;
    sprite.width = radius * 2;
    sprite.height = radius * 2;

    return (sprite)
  },

  spriteFromObjectData(data) {
    let sprite = new PIXI.Sprite(this.textures[data.type]);

    // Center the sprite's anchor point.
    sprite.anchor.set(0.5);

    if (data.position) {
      sprite.x = data.position.x;
      sprite.y = data.position.y;
    }

    sprite.width = data.size;
    sprite.height = data.size;

    return sprite;
  },

  detectionSprite(detection) {
    if (detection.type == "blip") {
      let circle = new PIXI.Graphics();
      circle.lineStyle(2, 0x993333);
      circle.beginFill(0xCC3333);

      circle.drawCircle(detection.position.x, detection.position.y, detection.size / 2);

      circle.endFill();

      return circle;
    } else if (detection.type == "explosion") {
      return this.gradientCircleSprite({
        centerX: detection.position.x,
        centerY: detection.position.y,
        radius: detection.size / 2,
        steps: 30,
        color: 0xFB0006,
        dividingFactor: 500,
      })

      // let circle = new PIXI.Graphics();
      // circle.lineStyle(2, 0x993333);
      // circle.beginFill(0xF58E51);
      //
      // circle.drawCircle(detection.position.x, detection.position.y, detection.size / 2);
      //
      // circle.endFill();
      //
      // return circle;
    } else {
      let sprite = new PIXI.Sprite(this.textures[detection.type]);

      // Center the sprite's anchor point.
      sprite.anchor.set(0.5);

      if (detection.target_aquired) {
        sprite.tint = 0xFF0000;
      }

      sprite.x = detection.position.x;
      sprite.y = detection.position.y;

      sprite.rotation = detection.rotation;

      sprite.width = detection.size;
      sprite.height = detection.size;

      return sprite;
    }
  },

  addObject(uuid, sprite) {
    this.spritesByUUID[uuid] = sprite;

    this.app.stage.addChild(sprite);
  },

  async mounted() {
    // Create a PixiJS application.
    this.app = new PIXI.Application();

    let [canvasHolder] = this.el.getElementsByClassName('canvas-holder')

    // Intialize the application.
    await this.app.init({ background: '#000', resizeTo: canvasHolder });

    // Then adding the application's canvas to the DOM body.
    canvasHolder.appendChild(this.app.canvas);

    let spaceImage = await PIXI.Assets.load('/images/space.png')
    const tilingSprite = new PIXI.TilingSprite({
      texture: PIXI.Texture.from('/images/space.png'),
      // texture: PIXI.Texture.WHITE,
      width: 100000,
      height: 100000,
      anchor: 0.5
    });

    this.app.stage.addChild(tilingSprite);

    let sunRadianceSprite = this.gradientCircleSprite({
      centerX: 0,
      centerY: 0,
      radius: 3000,
      steps: 50,
      // color: 0xCCCCCC,
      color: 0xFFFEEE,
      dividingFactor: 2000,
    })
    this.app.stage.addChild(sunRadianceSprite);

    this.textures = {
      sun: await PIXI.Assets.load('/images/sun.png'),
      ship: await PIXI.Assets.load('/images/spaceship.png'),
      missle: await PIXI.Assets.load('/images/missle.png'),
    };

    this.spritesByUUID = {};

    this.playerSprite = this.spriteFromObjectData({
      type: "ship",
      position: { x: 0, y: 0 },
      size: 20
    })
    this.app.stage.addChild(this.playerSprite);

    this.lastDetectionSprites = [];

    // this.handleEvent("add-objects", ({objects_by_uuid}) => {
    //   // console.log("add-objectS");

    //   for (const [uuid, data] of Object.entries(objects_by_uuid)) {
    //     this.addObject(uuid, this.spriteFromObjectData(data));
    //   }
    // })

    // this.handleEvent("assign-player-ship", ({uuid}) => {
    //   this.playerShipUUID = uuid;
    // })

    // this.handleEvent("add-object", ({uuid, data}) => {
    //   // console.log("add-object");

    //   this.addObject(uuid, this.spriteFromObjectData(data));
    // })

    // this.handleEvent("update-positions", ({positions_by_uuid}) => {
    //   // console.log("update-positions");

    //   for (const [uuid, position] of Object.entries(positions_by_uuid)) {
    //     let sprite = this.spritesByUUID[uuid];
    //     if (sprite) {
    //       sprite.x = position.x;
    //       sprite.y = position.y;

    //     } else {
    //       console.error(`Sprite with UUID ${uuid} not found`);
    //     }
    //   }

    //   let playerSprite = this.spritesByUUID[this.playerShipUUID];
    //   let canvas = this.app.canvas;
    //   if (playerSprite) {
    //     this.app.stage.pivot.x = playerSprite.x - (canvas.width / 2);
    //     this.app.stage.pivot.y = playerSprite.y - (canvas.height / 2);
    //   }
    // })

    this.handleEvent("update-player", ({ ship }) => {
      this.playerSprite.x = ship.position.x;
      this.playerSprite.y = ship.position.y;
      this.playerSprite.rotation = ship.rotation;

      this.playerSprite.tint = (ship.thrusting ? 0xffcf6a : 0xFFFFFF);

      this.app.stage.pivot.x = this.playerSprite.x - (this.app.canvas.width / 2);
      this.app.stage.pivot.y = this.playerSprite.y - (this.app.canvas.height / 2);
    })

    let updateDetections = (detections) => {
      console.log('detections')
      console.log(detections)

      this.lastDetectionSprites.forEach((detectionSprite) => {
        this.app.stage.removeChild(detectionSprite)
      })

      this.lastDetectionSprites = [];

      detections.forEach((detection) => {
        console.log(detection)
        let detectionSprite = this.detectionSprite(detection);

        this.app.stage.addChild(detectionSprite);

        this.lastDetectionSprites.push(detectionSprite);
      })

    }

    window.addEventListener('detections_data_initialized', event => updateDetections(event.target.detections_data.detections))
    window.addEventListener('detections_data_patched', event => updateDetections(event.target.detections_data.detections))

    // this.handleEvent("update-detections", ({detections}) => {
    //   updateDetections(detections);
    // })

    //     this.handleEvent("update-rotations", ({rotations_by_uuid}) => {
    //       // console.log("update-rotations", rotations_by_uuid);

    //       for (const [uuid, rotation] of Object.entries(rotations_by_uuid)) {
    //         let sprite = this.spritesByUUID[uuid];
    //         if (sprite) {
    //           sprite.rotation = rotation;
    //         } else {
    //           console.error(`Sprite with UUID ${uuid} not found`);
    //         }
    //       }
    //     })

    this.pushEvent("ready-to-render", {})
  }
}

export default GameBoard

