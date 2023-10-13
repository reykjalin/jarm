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

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
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

          const lqipElement = document.getElementById(`lqip-${lazyImage.id}`);

          // First we set the image position to absolute and set the width and height so it
          // floats over the canvas, using the canvas size to get the proper position.
          if (lqipElement) {
            const rect = lqipElement.getBoundingClientRect();
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
              lqipElement?.remove();
              lazyImage.style.removeProperty("top");
              lazyImage.style.removeProperty("left");
              lazyImage.style.removeProperty("height");
              lazyImage.style.removeProperty("width");
              lazyImage.style.removeProperty("position");
            });

            lazyImage.classList.remove("opacity-0");
            if (lqipElement) {
              lqipElement.style.opacity = 0;
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

// Wake lock for mobile on the upload page.
if ("wakeLock" in navigator) {
  const requestWakeLock = async () => {
    try {
      await navigator.wakeLock.request("screen");
    } catch (e) {
      console.error(`${e.name}, ${e.message}`);
    }
  };

  const handleVisibilityChange = () => {
    requestWakeLock();
  };

  const postButton = document.getElementById("post-button");
  if (postButton) {
    postButton.addEventListener("click", (_) => requestWakeLock());
  }

  document.addEventListener("visibilitychange", handleVisibilityChange);
} else {
  console.log("no wake lock");
}
