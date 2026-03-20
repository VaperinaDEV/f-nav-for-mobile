import { apiInitializer } from "discourse/lib/api";
import FNav from "../components/f-nav/f-nav";

function highlight(destination) {
  const tabs = document.querySelectorAll(".f-nav .tab");
  tabs.forEach((tab) => {
    if (compareURLs(tab.dataset.destination, destination)) {
      tab.classList.add("active");
    } else {
      tab.classList.remove("active");
    }
  });
}

function compareURLs(url1, url2) {
  if (!url1 || !url2) {
    return false;
  }
  // Clean URL parameters and trailing slashes
  const cleanURL1 = url1.replace(/(\?|#).*/g, "").replace(/\/$/, "");
  const cleanURL2 = url2.replace(/(\?|#).*/g, "").replace(/\/$/, "");
  
  // Exact match check
  if (cleanURL1 === cleanURL2) {
    return true;
  }
  
  // Special case for home page
  if (cleanURL1 === "/" || cleanURL1 === "") {
    return cleanURL2 === "/" || cleanURL2 === "";
  }
  
  // For other pages, check if paths match
  return cleanURL2.startsWith(cleanURL1 + "/") || cleanURL2 === cleanURL1;
}

function resolveMyAlias(url, username) {
  if (!url) {
    return "";
  }
  if (url.startsWith("/my/")) {
    return url.replace("/my/", `/u/${username}/`);
  }
  return url;
}

function updateDataDestinations(username) {
  const tabs = document.querySelectorAll(".f-nav .tab");
  tabs.forEach((tab) => {
    const originalDestination = tab.dataset.destination;
    if (originalDestination?.startsWith("/my/")) {
      tab.dataset.destination = resolveMyAlias(originalDestination, username);
    }
  });
}

export default apiInitializer("1.8.0", (api) => {
  const user = api.getCurrentUser();
  
  if (!user) {
    return;
  }

  api.onPageChange(() => {
    const navElement = document.querySelector(".f-nav");
    if (navElement) {
      updateDataDestinations(user.username_lower);
    }
  });

  const tabs = settings.f_nav_tabs;
  if (tabs.length === 0) {
    return;
  }

  // Highlight the corresponding tab when the page changes
  api.onAppEvent("page:changed", (data) => {
    const resolvedURL = resolveMyAlias(data.url, user.username_lower);
    highlight(resolvedURL);
  });

  tabs.forEach((tab) => {
    if (tab.destination) {
      const route = api.container.lookup(`route:${tab.destination}`);
      if (route) {
        route.reopen({
          actions: {
            didTransition() {
              const resolvedDestination = resolveMyAlias(tab.destination, user.username_lower);
              highlight(resolvedDestination);
              this._super(...arguments);
              return true;
            },
          },
        });
      }
    }
  });

  // FNav component connector
  api.renderInOutlet("above-footer", FNav);
});
