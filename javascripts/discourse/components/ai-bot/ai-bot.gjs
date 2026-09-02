import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { getOwner } from "@ember/application";
import { on } from "@ember/modifier";
import getURL from "discourse/lib/get-url";
import DButton from "discourse/ui-kit/d-button";
import dIcon from "discourse-common/helpers/d-icon";
import { i18n } from "discourse-i18n";

const AI_CONVERSATIONS_PANEL = "ai-conversations";

export default class AiBot extends Component {
  @service appEvents;
  @service sidebarState;

  get isInConversations() {
    return this.sidebarState.currentPanel?.key === AI_CONVERSATIONS_PANEL;
  }

  get manager() {
    return getOwner(this)?.lookup("service:ai-conversations-sidebar-manager");
  }

  get title() {
    return i18n(
      this.isInConversations
        ? "discourse_ai.ai_bot.exit"
        : "discourse_ai.ai_bot.shortcut_title"
    );
  }

  get icon() {
    return this.isInConversations ? "shuffle" : "far-discobot";
  }

  get href() {
    if (this.isInConversations) {
      return getURL(this.manager?.lastKnownAppURL || "/");
    }

    return getURL("/discourse-ai/ai-bot/conversations");
  }

  @action
  onClick(event) {
    event.stopPropagation();

    if (!this.isInConversations) {
      this.appEvents.trigger("discourse-ai:bot-header-icon-clicked");
    }
  }

  <template>
    <DButton
      @href={{this.href}}
      @action={{unless this.href this.onClick}}
      @icon={{this.icon}}
      title={{this.title}}
      class="ai-bot-button icon btn-flat"
    />
  </template>
}
