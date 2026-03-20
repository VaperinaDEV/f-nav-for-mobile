import Component from "@glimmer/component";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { service } from "@ember/service";
import { LinkTo } from "@ember/routing";
import { on } from "@ember/modifier";
import routeAction from "discourse/helpers/route-action";
import avatar from "discourse/helpers/bound-avatar-template";
import DMenu from "float-kit/components/d-menu";
import DButton from "discourse/components/d-button";
import discourseLater from "discourse-common/lib/later";
import DoNotDisturbModal from "discourse/components/modal/do-not-disturb";
import UserStatusModal from "discourse/components/modal/user-status";
import UserStatusBubble from "discourse/components/header/user-dropdown/user-status-bubble";
import formatAge from "discourse/helpers/format-age";
import dIcon from "discourse-common/helpers/d-icon";
import emoji from "discourse/helpers/emoji";
import concatClass from "discourse/helpers/concat-class";
import { ajax } from "discourse/lib/ajax";
import DoNotDisturb from "discourse/lib/do-not-disturb";
import { userPath } from "discourse/lib/url";
import { i18n } from "discourse-i18n";

export default class AvatarProfile extends Component {
  @service currentUser;
  @service site;
  @service siteSettings;
  @service userStatus;
  @service modal;

  saving = false;

  get shouldRender() {
    return this.site.mobileView && this.currentUser;
  }

  get showToggleAnonymousButton() {
    return (
      this.currentUser.can_post_anonymously || this.currentUser.is_anonymous
    );
  }

  get isInDoNotDisturb() {
    return !!this.#doNotDisturbUntilDate;
  }

  get doNotDisturbDateTime() {
    return this.#doNotDisturbUntilDate.getTime();
  }

  get showDoNotDisturbEndDate() {
    return !DoNotDisturb.isEternal(
      this.currentUser.get("do_not_disturb_until")
    );
  }

  get #doNotDisturbUntilDate() {
    if (!this.currentUser.get("do_not_disturb_until")) {
      return;
    }
    const date = new Date(this.currentUser.get("do_not_disturb_until"));
    if (date < new Date()) {
      return;
    }
    return date;
  }

  get isPresenceHidden() {
    return this.currentUser.get("user_option.hide_presence");
  }

  @action
  doNotDisturbClick() {
    if (this.saving) {
      return;
    }
    this.saving = true;
    if (this.currentUser.do_not_disturb_until) {
      return this.currentUser.leaveDoNotDisturb().finally(() => {
        this.saving = false;
      });
    } else {      
      this.dMenu.close();

      // Set delay to ensure modal is opening correctly
      discourseLater(() => {
        this.modal.show(DoNotDisturbModal);
        this.saving = false;
      }, 100);
    }
  }

  @action
  togglePresence() {
    this.currentUser.set("user_option.hide_presence", !this.isPresenceHidden);
    this.currentUser.save(["hide_presence"]);
  }

  @action
  setUserStatusClick() {
    this.dMenu.close();
    
    // Set delay to ensure modal is opening correctly
    discourseLater(() => {
      this.modal.show(UserStatusModal, {
        model: {
          status: this.currentUser.status,
          pauseNotifications: this.currentUser.isInDoNotDisturb(),
          saveAction: (status, pauseNotifications) =>
            this.userStatus.set(status, pauseNotifications),
          deleteAction: () => this.userStatus.clear(),
        },
      });
    }, 100);
  }

  @action
  async toggleAnonymous() {
    await ajax(userPath("toggle-anon"), { type: "POST" });
    window.location.reload();
  }

  @action
  onRegisterApi(api) {
    this.dMenu = api;
  }

  <template>
    {{#if this.shouldRender}}
      <li id="current-user" class="header-dropdown-toggle current-user user-menu-panel">
        <DMenu
          @identifier="avatar-profile"
          class="icon btn-flat"
          @modalForMobile={{true}}
          @onRegisterApi={{this.onRegisterApi}}
        >
          <:trigger>
            {{avatar this.currentUser.avatar_template "medium"}}
            {{#if this.currentUser.status}}
              <UserStatusBubble
                @timezone={{this.this.currentUser.user_option.timezone}}
                @status={{this.currentUser.status}}
              />
            {{/if}}
          </:trigger>
          <:content as |args|>
            <ul class="user-menu-items">
              {{#if this.siteSettings.enable_user_status}}
                <li {{on "click" args.close}} class="set-user-status">
                  <DButton
                    @action={{this.setUserStatusClick}}
                    class="btn-flat profile-tab-btn"
                  >
                    {{#if this.currentUser.status}}
                      {{emoji this.currentUser.status.emoji}}
                      <span class="item-label">
                        {{this.currentUser.status.description}}
                        {{#if this.currentUser.status.ends_at}}
                          {{formatAge this.currentUser.status.ends_at}}
                        {{/if}}
                      </span>
                    {{else}}
                      {{dIcon "circle-plus"}}
                      <span class="item-label">
                        {{i18n "user_status.set_custom_status"}}
                      </span>
                    {{/if}}
                  </DButton>
                </li>
              {{/if}}
            
              <li
                class={{concatClass
                  "presence-toggle"
                  (unless this.isPresenceHidden "enabled")
                }}
                title={{i18n "presence_toggle.title"}}
              >
                <DButton @action={{this.togglePresence}} class="btn-flat profile-tab-btn">
                  {{dIcon (if this.isPresenceHidden "toggle-off" "toggle-on")}}
                  <span class="item-label">
                    {{#if this.isPresenceHidden}}
                      {{i18n "presence_toggle.offline"}}
                    {{else}}
                      {{i18n "presence_toggle.online"}}
                    {{/if}}
                  </span>
                </DButton>
              </li>
            
              <li
                class={{concatClass "do-not-disturb" (if this.isInDoNotDisturb "enabled")}}
              >
                <DButton
                  @action={{this.doNotDisturbClick}}
                  class="btn-flat profile-tab-btn"
                >
                  {{dIcon (if this.isInDoNotDisturb "toggle-on" "toggle-off")}}
                  <span class="item-label">
                    {{#if this.isInDoNotDisturb}}
                      <span>{{i18n "pause_notifications.label"}}</span>
                      {{#if this.showDoNotDisturbEndDate}}
                        {{formatAge this.doNotDisturbDateTime}}
                      {{/if}}
                    {{else}}
                      {{i18n "pause_notifications.label"}}
                    {{/if}}
                  </span>
                </DButton>
              </li>
            
              <hr />
            
              <li {{on "click" args.close}} class="summary">
                <LinkTo @route="user.summary" @model={{this.currentUser}}>
                  {{dIcon "user"}}
                  <span class="item-label">
                    {{i18n "user.summary.title"}}
                  </span>
                </LinkTo>
              </li>
            
              <li {{on "click" args.close}} class="activity">
                <LinkTo @route="userActivity" @model={{this.currentUser}}>
                  {{dIcon "bars-staggered"}}
                  <span class="item-label">
                    {{i18n "user.activity_stream"}}
                  </span>
                </LinkTo>
              </li>
            
              {{#if this.currentUser.can_invite_to_forum}}
                <li {{on "click" args.close}} class="invites">
                  <LinkTo @route="userInvited" @model={{this.currentUser}}>
                    {{dIcon "user-plus"}}
                    <span class="item-label">
                      {{i18n "user.invited.title"}}
                    </span>
                  </LinkTo>
                </li>
              {{/if}}
            
              <li {{on "click" args.close}} class="drafts">
                <LinkTo @route="userActivity.drafts" @model={{this.currentUser}}>
                  {{dIcon "user_menu.drafts"}}
                  <span class="item-label">
                    {{#if this.currentUser.draft_count}}
                      {{i18n "drafts.label_with_count" count=this.currentUser.draft_count}}
                    {{else}}
                      {{i18n "drafts.label"}}
                    {{/if}}
                  </span>
                </LinkTo>
              </li>
            
              <li {{on "click" args.close}} class="preferences">
                <LinkTo @route="preferences" @model={{this.currentUser}}>
                  {{dIcon "gear"}}
                  <span class="item-label">
                    {{i18n "user.preferences.title"}}
                  </span>
                </LinkTo>
              </li>
            
              {{#if this.showToggleAnonymousButton}}
                <li
                  {{on "click" args.close}}
                  class={{if
                    this.currentUser.is_anonymous
                    "disable-anonymous"
                    "enable-anonymous"
                  }}
                >
                  <DButton
                    @action={{this.toggleAnonymous}}
                    class="btn-flat profile-tab-btn"
                  >
                    {{#if this.currentUser.is_anonymous}}
                      {{dIcon "ban"}}
                      <span class="item-label">
                        {{i18n "switch_from_anon"}}
                      </span>
                    {{else}}
                      {{dIcon "user-secret"}}
                      <span class="item-label">
                        {{i18n "switch_to_anon"}}
                      </span>
                    {{/if}}
                  </DButton>
                </li>
              {{/if}}

              {{#each settings.profile_extra_items as |item|}}
                <li {{on "click" args.close}} class="custom-extra-item">
                  <a
                    title={{item.label}}
                    href={{item.url}}
                  >
                    {{#if item.icon}}
                      {{dIcon item.icon}}
                    {{/if}}
                    <span class="item-label">
                      {{item.label}}
                    </span>
                  </a>
                </li>
              {{/each}}

              <hr />
        
              <li class="logout">
                <DButton @action={{routeAction "logout"}} class="btn-flat profile-tab-btn">
                  {{dIcon "right-from-bracket"}}
                  <span class="item-label">
                    {{i18n "user.log_out"}}
                  </span>
                </DButton>
              </li>
            </ul>
          </:content>
        </DMenu>
      </li>
    {{/if}}
  </template>
}
