import Component from "@ember/component";
import { service } from "@ember/service";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import willDestroy from "@ember/render-modifiers/modifiers/will-destroy";
import { htmlSafe } from "@ember/template";
import DiscourseURL from "discourse/lib/url";
import DoNotDisturb from "discourse/lib/do-not-disturb";
import { scrollTop } from "discourse/mixins/scroll-top";
import FNavItem from "./f-nav-item";

const SCROLL_MAX = 30;
const HIDDEN_F_NAV_CLASS = "f-nav-hidden";

export default class FNav extends Component {
  @service router;
  @service currentUser;
  @service site;
  @service siteSettings;
  @service topicTrackingState;

  tabs = settings.f_nav_tabs;
  lastScrollTop = 0;

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

  // Scroll handling
  @action
  scrollListener() {
    const scrollTop = window.scrollY;
    const body = document.body;
    const shouldHide = this.lastScrollTop < scrollTop && scrollTop > SCROLL_MAX;
    
    body.classList.toggle(HIDDEN_F_NAV_CLASS, shouldHide);
    this.lastScrollTop = scrollTop;
  }

  @action
  setupScrollListener() {
    document.addEventListener("scroll", this.scrollListener);
  }

  @action
  removeScrollListener() {
    document.removeEventListener("scroll", this.scrollListener);
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