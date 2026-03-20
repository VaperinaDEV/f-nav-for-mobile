import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { optionalRequire } from "discourse/lib/utilities";
import DMenu from "float-kit/components/d-menu";
import dIcon from "discourse-common/helpers/d-icon";
import ChatIcon from "../messages/chat-icon";
import MessagesIcon from "../messages/messages-icon";

export default class MultiTabMessages extends Component {
  @service site;
  @service currentUser;
  @service siteSettings;

  get canUseChat() {
    return (
      this.currentUser?.has_chat_enabled && this.siteSettings?.chat_enabled
    );
  }

  get ChatHeaderIconUnreadIndicator() {
    return optionalRequire(
      "discourse/plugins/chat/discourse/components/chat/header/icon/unread-indicator"
    );
  }

  get currentUserInDnD() {
    return this.args.currentUserInDnD || this.currentUser.isInDoNotDisturb();
  }

  @action
  onRegisterApi(api) {
    this.dMenu = api;
  }

  @action
  closeMenu() {
    this.dMenu.close();
  }

  <template>
    {{#if this.canUseChat}}
      <DMenu
        @arrow={{true}}
        @identifier="multi-tab"
        @closeOnScroll={{true}}
        id="multi-tab-messages"
        class="icon btn-flat"
        @modalForMobile={{false}}
        @onRegisterApi={{this.onRegisterApi}}
      >
        <:trigger>
          {{#unless this.currentUserInDnD}}
            {{#if this.currentUser.new_personal_messages_notifications_count}}
              <div class="message-unread-indicator -urgent"></div>
            {{/if}}
            <this.ChatHeaderIconUnreadIndicator
              @urgentCount={{@urgentCount}}
              @unreadCount={{@unreadCount}}
              @indicatorPreference={{@indicatorPreference}}
            />
          {{/unless}}
          {{dIcon "message"}}
        </:trigger>
        <:content>
          <ul class="messages-options">
            <li class="messages-icon">
              <MessagesIcon />
            </li>
            <li {{on "click" this.closeMenu}} class="chat-header-icon">
              <ChatIcon />
            </li>
          </ul>
        </:content>
      </DMenu>
    {{else}}
      <MessagesIcon />
    {{/if}}
  </template>
}
