// Match opted-in brand images to pkgdown's existing light/dark/auto control.
(function () {
  "use strict";

  function initialiseBrandImages() {
    var systemDark = window.matchMedia("(prefers-color-scheme: dark)");
    var pictures = document.querySelectorAll(
      "picture.cttir-readme-logo source.cttir-logo-dark-source"
    );
    var navbarImages = [];

    function isDark(element) {
      var owner = element.closest("[data-bs-theme]");
      var theme = owner && owner.getAttribute("data-bs-theme");
      if (theme === "dark") return true;
      if (theme === "light") return false;
      return systemDark.matches;
    }

    function updateImages() {
      pictures.forEach(function (source) {
        source.media = isDark(source) ? "all" : "not all";
      });
      navbarImages.forEach(function (image) {
        image.element.src = isDark(image.element) ? image.dark : image.light;
      });
    }

    document.querySelectorAll("img.themakr-navbar-logo[data-cttir-dark-src]")
      .forEach(function (element) {
        var light = new URL(element.src, document.baseURI);
        var dark = new URL(element.getAttribute("data-cttir-dark-src"), document.baseURI);
        if (light.origin !== window.location.origin ||
            dark.origin !== window.location.origin ||
            !/\/logo\.(svg|png)$/i.test(light.pathname)) return;
        var probe = new Image();
        probe.onload = function () {
          navbarImages.push({ element: element, light: light.href, dark: dark.href });
          // pkgdown repeats the same artwork beside the homepage heading.
          document.querySelectorAll(".page-header > img.logo").forEach(function (logo) {
            if (logo.src === light.href) {
              navbarImages.push({ element: logo, light: light.href, dark: dark.href });
            }
          });
          updateImages();
        };
        // Older packages keep their original opaque logo when no dark asset exists.
        probe.onerror = function () {};
        probe.src = dark.href;
      });

    updateImages();
    new MutationObserver(updateImages).observe(document.documentElement, {
      attributes: true,
      attributeFilter: ["data-bs-theme"]
    });
    if (systemDark.addEventListener) {
      systemDark.addEventListener("change", updateImages);
    } else {
      systemDark.addListener(updateImages);
    }
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initialiseBrandImages);
  } else {
    initialiseBrandImages();
  }
}());
