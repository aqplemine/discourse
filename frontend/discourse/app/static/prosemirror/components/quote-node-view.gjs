import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import didUpdate from "@ember/render-modifiers/modifiers/did-update";
import { ajax } from "discourse/lib/ajax";
import { userPath } from "discourse/lib/url";
import dBoundAvatarTemplate from "discourse/ui-kit/helpers/d-bound-avatar-template";

const avatarTemplates = new Map();

function lookupAvatarTemplate(username) {
  const key = username.toLowerCase();

  if (!avatarTemplates.has(key)) {
    avatarTemplates.set(
      key,
      ajax(userPath(`${encodeURIComponent(username)}/card.json`), {
        // rendering a quote is not the reader visiting a profile
        data: { skip_track_visit: true },
      })
        .then(({ user }) => user?.avatar_template)
        .catch(() => null)
    );
  }

  return avatarTemplates.get(key);
}

export default class QuoteNodeView extends Component {
  @tracked avatar;

  constructor() {
    super(...arguments);
    this.loadAvatar();
  }

  get username() {
    return this.args.node.attrs.username;
  }

  get displayName() {
    return this.args.node.attrs.displayName || this.username;
  }

  // keyed by username, so an avatar is never shown for a different user,
  // including while a replacement is still loading
  get avatarTemplate() {
    return this.avatar?.username === this.username
      ? this.avatar.template
      : null;
  }

  @action
  async loadAvatar() {
    const { username } = this;
    if (!username) {
      return;
    }

    const template = await lookupAvatarTemplate(username);
    if (!this.isDestroying && !this.isDestroyed) {
      this.avatar = { username, template };
    }
  }

  <template>
    {{~! strip whitespace ~}}{{#if this.username~}}
      <div class="title" {{didUpdate this.loadAvatar this.username}}>
        {{~#if this.avatarTemplate~}}
          {{dBoundAvatarTemplate this.avatarTemplate "tiny"}}
        {{~/if~}}
        {{~this.displayName}}:</div>
    {{~/if~}}{{~yield~}}{{~! strip whitespace ~}}
  </template>
}
