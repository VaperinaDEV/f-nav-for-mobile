import Component from "@ember/component";
import { service } from "@ember/service";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import willDestroy from "@ember/render-modifiers/modifiers/will-destroy";
import { htmlSafe } from "@ember/template";
import DiscourseURL from "discourse/lib/url";
import DoNotDisturb from "discourse/lib/do-not-disturb";
import FNavItem from "./f-nav-item";

const SCROLL_MAX = 30;
const HIDDEN_F_NAV_CLASS = "f-nav-hidden";
const MODAL_OPEN_CLASS = "modal-open";
const SCROLL_LOCK_CLASS = "scroll-lock";

export default class FNav extends Component {
  @service router;
  @service currentUser;
  @service site;
  @service siteSettings;
  @service topicTrackingState;

  tabs = settings.f_nav_tabs;

  // Scroll handling
  lastScrollTop = 0;
  scrollTimeout = null;

  @action
  scrollListener(event) {
    if (
      document.documentElement.classList.contains(MODAL_OPEN_CLASS) ||
      document.documentElement.classList.contains(SCROLL_LOCK_CLASS)
    ) {
      return;
    }

    if (this.scrollTimeout) {
      return;
    }

    this.scrollTimeout = requestAnimationFrame(() => {
      const currentScroll = window.scrollY;
      const shouldHide = this.lastScrollTop < currentScroll && currentScroll > SCROLL_MAX;

      document.body.classList.toggle(HIDDEN_F_NAV_CLASS, shouldHide);
      this.lastScrollTop = currentScroll;
      this.scrollTimeout = null;
    });
  }

  @action
  setupScrollListener() {
    this.lastScrollTop = window.scrollY;
    document.addEventListener("scroll", this.scrollListener, { passive: true });
  }

  @action
  removeScrollListener() {
    document.removeEventListener("scroll", this.scrollListener);
  }

  // Computed properties for visibility and states
  get shouldShowNav() {
    return this.currentUser && this.site.mobileView && this.tabs.length;
  }

  get canUseChat() {
    return this.currentUser?.has_chat_enabled && this.siteSettings?.chat_enabled;
  }

  get isTopicRoute() {
    return this.router.currentRouteName.startsWith("topic.");
  }

  // DoNotDisturb related computeds
  get isInDoNotDisturbBadge() {
    return this.currentUser.isInDoNotDisturb();
  }

  get doNotDisturbDateTime() {
    const date = this.#getDoNotDisturbDate();
    return date?.getTime();
  }

  get showDoNotDisturbEndDate() {
    return !DoNotDisturb.isEternal(this.currentUser.get("do_not_disturb_until"));
  }

  // Destination computeds
  get homeDestination() {
    return "/";
  }

  get messagesDestination() {
    return `/u/${this.currentUser.username_lower}/messages`;
  }

  get searchDestination() {
    return "/search";
  }

  get notificationsDestination() {
    if (this.currentUser.unseen_reviewable_count) {
      return "/review";
    }
    const base = `/u/${this.currentUser.username_lower}/notifications`;
    return this.currentUser.all_unread_notifications_count 
      ? `${base}?filter=unread` 
      : base;
  }

  get aiBotDestination() {
    return "/discourse-ai/ai-bot/conversations";
  }

  // Private methods
  #getDoNotDisturbDate() {
    const until = this.currentUser.get("do_not_disturb_until");
    if (!until) {
      return null;
    }
    
    const date = new Date(until);
    return date < new Date() ? null : date;
  }

  #handleElementClick(elementId) {
    const element = document.getElementById(elementId);
    element?.click();
  }

  // Navigation actions
  @action
  homeTabRouteSwitcher() {
    this.isTopicRoute ? window.history.back() : DiscourseURL.routeTo("/");
  }

  @action
  toggleHamburger() {
    this.#handleElementClick("toggle-hamburger-menu");
  }

  @action
  toggleNotification() {
    this.#handleElementClick("toggle-current-user");
  }

  @action
  navigateNotifications() {
    DiscourseURL.routeTo(this.notificationsDestination);
  }

  @action
  toggleSearchMenu() {
    this.#handleElementClick("search-button");
  }

  @action
  navigate(tab) {
    DiscourseURL.routeTo(tab.destination);
  }

  <template>
    {{#if this.shouldShowNav}}
      <div
        class="f-nav"
        {{didInsert this.setupScrollListener}}
        {{willDestroy this.removeScrollListener}}
      >
        {{#each this.tabs as |tab|}}
          <FNavItem
            @tab={{tab}}
            @isTopicRoute={{this.isTopicRoute}}
            @canUseChat={{this.canUseChat}}
            @isInDoNotDisturbBadge={{this.isInDoNotDisturbBadge}}
            @showDoNotDisturbEndDate={{this.showDoNotDisturbEndDate}}
            @doNotDisturbDateTime={{this.doNotDisturbDateTime}}
            @currentUser={{this.currentUser}}
            @topicTrackingState={{this.topicTrackingState}}
            @homeDestination={{this.homeDestination}}
            @messagesDestination={{this.messagesDestination}}
            @searchDestination={{this.searchDestination}}
            @notificationsDestination={{this.notificationsDestination}}
            @aiBotDestination={{this.aiBotDestination}}
            @onHomeClick={{this.homeTabRouteSwitcher}}
            @onHamburgerClick={{this.toggleHamburger}}
            @onNotificationClick={{this.navigateNotifications}}
            @onToggleNotification={{this.toggleNotification}}
            @onSearchClick={{this.toggleSearchMenu}}
            @onNavigate={{this.navigate}}
          />
        {{/each}}
      </div>
    {{/if}}
  </template>
}
