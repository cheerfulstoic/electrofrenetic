import * as PIXI from 'pixi.js';

let GameBoard = {
  async mounted() {
    // Create a PixiJS application.
    console.log({Application: PIXI.Application})
    const app = new PIXI.Application();
    console.log({app})

    // Intialize the application.
    await app.init({ background: '#1099bb', resizeTo: window });

    // Then adding the application's canvas to the DOM body.
    this.el.appendChild(app.canvas);

    // Load the bunny texture.
    const texture = await PIXI.Assets.load('https://pixijs.com/assets/bunny.png');

    // Create a new Sprite from an image path.
    const bunny = new PIXI.Sprite(texture);

    // Add to stage.
    app.stage.addChild(bunny);

    // Center the sprite's anchor point.
    bunny.anchor.set(0.5);

    // Move the sprite to the center of the screen.
    // bunny.x = app.screen.width / 2;
    // bunny.y = app.screen.height / 2;

    bunny.x = 10;
    bunny.y = 10;

    // Add an animation loop callback to the application's ticker.
    app.ticker.add((time) =>
    {
        /**
         * Just for fun, let's rotate mr rabbit a little.
         * Time is a Ticker object which holds time related data.
         * Here we use deltaTime, which is the time elapsed between the frame callbacks
         * to create frame-independent transformation. Keeping the speed consistent.
         */
        bunny.rotation += 0.1 * time.deltaTime;
    });


    // this.el.addEventListener("input", e => {
    //   let match = this.el.value.replace(/\D/g, "").match(/^(\d{3})(\d{3})(\d{4})$/)
    //   if(match) {
    //     this.el.value = `${match[1]}-${match[2]}-${match[3]}`
    //   }
    // })
  }

  async updated() {
    console.log('updated')
    // console.log({hi: this.el.data})
  }
}

export default GameBoard

