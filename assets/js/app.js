// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "./vendor/some-package.js"
//
// Alternatively, you can `npm install some-package` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";
import { decode } from "blurhash";

const blurhashHook = {
  mounted() {
    // this.el is a canvas element.
    const blurhash = this.el.getAttribute("data-blurhash");
    const pixels = decode(blurhash, 30, 30);

    const tempCanvas = document.createElement("canvas");
    const tempCtx = tempCanvas.getContext("2d");
    const imageData = tempCtx.createImageData(30, 30);
    imageData.data.set(pixels);
    tempCtx.putImageData(imageData, 0, 0);

    const scaleX = this.el.width / 30;
    const scaleY = this.el.height / 30;

    const ctx = this.el.getContext("2d");
    ctx.scale(scaleX, scaleY);
    ctx.drawImage(tempCanvas, 0, 0);
  },
};

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  hooks: { BlurHash: blurhashHook },
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;

// Lazy loading images.
window.addEventListener("phx:page-loading-stop", () => {
  const lazyImages = [].slice.call(document.querySelectorAll("img.lazy"));
  const lazyVideos = [].slice.call(document.querySelectorAll("video.lazy"));

  if ("IntersectionObserver" in window) {
    const lazyImageObserver = new IntersectionObserver(function (
      entries,
      observer
    ) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          const lazyImage = entry.target;

          const canvasElement = document.getElementById(
            `canvas-${lazyImage.id}`
          );

          // First we set the image position to absolute and set the width and height so it
          // floats over the canvas, using the canvas size to get the proper position.
          if (canvasElement) {
            const rect = canvasElement.getBoundingClientRect();
            lazyImage.style.top = 0;
            lazyImage.style.left = 0;
            lazyImage.style.height = `${rect.height}px`;
            lazyImage.style.width = `${rect.width}px`;
            lazyImage.style.position = "absolute";
          }

          // Then we load the image.
          lazyImage.classList.remove("lazy");
          lazyImage.src = lazyImage.dataset.src;
          lazyImageObserver.unobserve(lazyImage);

          // When the image is loaded we cross fade the image and canvas.
          lazyImage.addEventListener("load", () => {
            // Once the image has transitioned in we remove the canvas and set the
            // image position back to normal.
            lazyImage.addEventListener("transitionend", () => {
              canvasElement?.remove();
              lazyImage.style.removeProperty("top");
              lazyImage.style.removeProperty("left");
              lazyImage.style.removeProperty("height");
              lazyImage.style.removeProperty("width");
              lazyImage.style.removeProperty("position");
            });

            lazyImage.classList.remove("opacity-0");
            if (canvasElement) {
              canvasElement.style.opacity = 0;
            }
          });
        }
      });
    });
    const lazyVideoObserver = new IntersectionObserver(function (
      entries,
      observer
    ) {
      entries.forEach(function (video) {
        if (video.isIntersecting) {
          for (const source in video.target.children) {
            const videoSource = video.target.children[source];
            if (
              typeof videoSource.tagName === "string" &&
              videoSource.tagName === "SOURCE"
            ) {
              videoSource.src = videoSource.dataset.src;
            }
          }

          video.target.load();
          video.target.classList.remove("lazy");
          lazyVideoObserver.unobserve(video.target);
        }
      });
    });

    lazyImages.forEach(function (lazyImage) {
      lazyImageObserver.observe(lazyImage);
    });
    lazyVideos.forEach(function (lazyVideo) {
      lazyVideoObserver.observe(lazyVideo);
    });
  } else {
    // TODO: Possibly fall back to event handlers here
  }
});
